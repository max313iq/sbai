#!/usr/bin/env python3
"""
Lightweight self-healing PyTorch training workload for GPU node validation.
"""

from __future__ import annotations

import argparse
import os
import random
import sys
import time
from dataclasses import dataclass
from datetime import datetime

import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, Dataset


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--cpu-threads", type=int, default=int(os.environ.get("OMP_NUM_THREADS", "4")))
    p.add_argument("--max-gpu-percent", type=int, default=20)
    p.add_argument("--max-cpu-percent", type=float, default=float(os.environ.get("MAX_CPU_PERCENT", "5")))
    p.add_argument("--epochs", type=int, default=1000000)
    p.add_argument("--batch-size", type=int, default=4)
    p.add_argument("--samples", type=int, default=800)
    p.add_argument("--checkpoint-every", type=int, default=50)
    return p.parse_args()


@dataclass
class Config:
    cpu_threads: int
    max_gpu_percent: int
    max_cpu_percent: float
    epochs: int
    batch_size: int
    samples: int
    checkpoint_every: int


class RandomImageDataset(Dataset):
    def __init__(self, size: int, classes: int = 1000, image_size: int = 224):
        self.size = size
        self.classes = classes
        self.image_size = image_size

    def __len__(self) -> int:
        return self.size

    def __getitem__(self, idx: int):
        x = torch.randn(3, self.image_size, self.image_size)
        y = random.randint(0, self.classes - 1)
        return x, y


class TinyConvNet(nn.Module):
    def __init__(self, classes: int = 1000):
        super().__init__()
        self.net = nn.Sequential(
            nn.Conv2d(3, 32, 3, stride=2, padding=1),
            nn.ReLU(inplace=True),
            nn.Conv2d(32, 64, 3, stride=2, padding=1),
            nn.ReLU(inplace=True),
            nn.Conv2d(64, 128, 3, stride=2, padding=1),
            nn.ReLU(inplace=True),
            nn.AdaptiveAvgPool2d((1, 1)),
        )
        self.fc = nn.Linear(128, classes)

    def forward(self, x):
        x = self.net(x)
        x = torch.flatten(x, 1)
        return self.fc(x)


def save_ckpt(model: nn.Module, opt: optim.Optimizer, epoch: int, loss: float) -> None:
    os.makedirs("/workspace/checkpoints", exist_ok=True)
    path = f"/workspace/checkpoints/model_epoch_{epoch}.pth"
    torch.save(
        {
            "epoch": epoch,
            "loss": loss,
            "model_state_dict": model.state_dict(),
            "optimizer_state_dict": opt.state_dict(),
            "timestamp": datetime.utcnow().isoformat(),
        },
        path,
    )
    print(f"[ckpt] saved {path}", flush=True)


def main() -> int:
    args = parse_args()
    cfg = Config(
        cpu_threads=max(1, args.cpu_threads),
        max_gpu_percent=max(1, args.max_gpu_percent),
        max_cpu_percent=min(100.0, max(1.0, args.max_cpu_percent)),
        epochs=max(1, args.epochs),
        batch_size=max(1, args.batch_size),
        samples=max(32, args.samples),
        checkpoint_every=max(1, args.checkpoint_every),
    )

    random.seed(42)
    np.random.seed(42)
    torch.manual_seed(42)
    torch.set_num_threads(cfg.cpu_threads)
    torch.set_num_interop_threads(1)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Start: {datetime.now().isoformat()}", flush=True)
    print(f"PyTorch: {torch.__version__}", flush=True)
    print(f"Using device: {device}", flush=True)
    print(f"CPU target max: {cfg.max_cpu_percent:.1f}%", flush=True)
    if torch.cuda.is_available():
        print(f"CUDA: {torch.version.cuda}", flush=True)
        print(f"GPU: {torch.cuda.get_device_name(0)}", flush=True)

    ds = RandomImageDataset(size=cfg.samples)
    dl = DataLoader(ds, batch_size=cfg.batch_size, shuffle=True, num_workers=1, pin_memory=torch.cuda.is_available())
    model = TinyConvNet().to(device)
    opt = optim.Adam(model.parameters(), lr=1e-3)
    loss_fn = nn.CrossEntropyLoss()

    # Throttle factor keeps GPU utilization intentionally moderate.
    throttle_sleep = max(0.05, (100 - cfg.max_gpu_percent) / 100.0)
    if device.type == "cpu":
        throttle_sleep = max(throttle_sleep, 0.30)
    target_cpu_percent = cfg.max_cpu_percent
    last_cpu_time = time.process_time()
    last_wall_time = time.time()

    for epoch in range(1, cfg.epochs + 1):
        model.train()
        running = 0.0
        correct = 0
        total = 0
        start_t = time.time()

        for i, (x, y) in enumerate(dl):
            x = x.to(device, non_blocking=True)
            y = y.to(device, non_blocking=True)

            opt.zero_grad(set_to_none=True)
            out = model(x)
            loss = loss_fn(out, y)
            loss.backward()
            opt.step()

            running += float(loss.item())
            pred = out.argmax(dim=1)
            total += int(y.size(0))
            correct += int((pred == y).sum().item())
            now_cpu_time = time.process_time()
            now_wall_time = time.time()
            cpu_delta = max(0.0, now_cpu_time - last_cpu_time)
            wall_delta = max(1e-6, now_wall_time - last_wall_time)
            last_cpu_time = now_cpu_time
            last_wall_time = now_wall_time

            # Adaptive sleep to keep process CPU usage near the configured target.
            required_wall = cpu_delta * 100.0 / target_cpu_percent
            extra_sleep = max(0.0, required_wall - wall_delta)
            time.sleep(throttle_sleep + min(extra_sleep, 5.0))
            if i % 10 == 0:
                acc = 100.0 * correct / max(1, total)
                print(f"[epoch {epoch}] step {i}/{len(dl)} loss={running/(i+1):.4f} acc={acc:.2f}%", flush=True)

        elapsed = time.time() - start_t
        avg_loss = running / max(1, len(dl))
        acc = 100.0 * correct / max(1, total)
        print(f"[epoch {epoch}] done loss={avg_loss:.4f} acc={acc:.2f}% time={elapsed:.1f}s", flush=True)

        if epoch % cfg.checkpoint_every == 0:
            save_ckpt(model, opt, epoch, avg_loss)

        time.sleep(2.0)

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("Interrupted by user", flush=True)
        raise SystemExit(0)
    except Exception as exc:  # pylint: disable=broad-except
        print(f"Fatal training error: {exc}", file=sys.stderr, flush=True)
        raise SystemExit(1)
