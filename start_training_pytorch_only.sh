#!/bin/bash
set -Eeuo pipefail

export TERM=xterm
export LC_ALL=C
export LANG=C.UTF-8
export PYTHONUNBUFFERED=1

enforce_host_driver_library_precedence() {
    local -a preferred_paths=(
        "/usr/local/nvidia/lib64"
        "/usr/local/nvidia/lib"
        "/usr/lib/x86_64-linux-gnu"
    )
    local -a existing_paths=()
    local -a merged_paths=()
    local path=""
    local seen=":"
    
    IFS=':' read -r -a existing_paths <<< "${LD_LIBRARY_PATH:-}"
    for path in "${preferred_paths[@]}" "${existing_paths[@]}"; do
        [ -n "$path" ] || continue
        case "$path" in
            /usr/local/cuda/compat|/usr/local/cuda-*/compat)
                continue
                ;;
        esac
        case "$seen" in
            *":$path:"*)
                continue
                ;;
        esac
        merged_paths+=("$path")
        seen="${seen}${path}:"
    done
    
    LD_LIBRARY_PATH=$(IFS=:; echo "${merged_paths[*]}")
    export LD_LIBRARY_PATH
}
enforce_host_driver_library_precedence

mkdir -p /workspace/logs /workspace/checkpoints
echo "Starting PyTorch-only mode..."

while true; do
    python3 -u /workspace/train_model.py \
        --cpu-threads "${OMP_NUM_THREADS:-4}" \
        --max-gpu-percent "${MAX_GPU_PERCENT:-20}" \
        2>&1 | tee -a /workspace/logs/training.log
    echo "Training process exited, restarting in 5s..."
    sleep 5
done
