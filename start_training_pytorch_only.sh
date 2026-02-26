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

LOCK_FILE="/tmp/start_training_pytorch_only.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "Another start_training_pytorch_only.sh instance is already running. Exiting."
    exit 1
fi

TRAINING_LOG="/workspace/logs/training.log"
MAX_LOG_SIZE_BYTES="${MAX_LOG_SIZE_BYTES:-10485760}"

rotate_training_log_if_needed() {
    if [ -f "$TRAINING_LOG" ]; then
        local size
        size=$(stat -c%s "$TRAINING_LOG" 2>/dev/null || echo 0)
        if [ "$size" -ge "$MAX_LOG_SIZE_BYTES" ]; then
            mv -f "$TRAINING_LOG" "${TRAINING_LOG}.1" 2>/dev/null || true
        fi
    fi
}

stop_requested=false
handle_shutdown() {
    stop_requested=true
}
trap handle_shutdown SIGINT SIGTERM

echo "Starting PyTorch-only mode..."

while true; do
    rotate_training_log_if_needed
    python3 -u /workspace/train_model.py \
        --cpu-threads "${OMP_NUM_THREADS:-4}" \
        --max-gpu-percent "${MAX_GPU_PERCENT:-20}" \
        2>&1 | tee -a "$TRAINING_LOG"
    if [ "$stop_requested" = true ]; then
        echo "Shutdown requested, stopping PyTorch-only loop."
        break
    fi
    echo "Training process exited, restarting in 5s..."
    sleep 5
done
