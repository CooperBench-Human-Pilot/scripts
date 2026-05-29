FROM python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install uv (modern Python package manager)
RUN pip install uv

# Clone the repository and checkout the specific commit
WORKDIR /workspace
RUN git clone https://github.com/huggingface/datasets.git repo && \
    cd repo && \
    git checkout e229fade6d1a5b8eedb02370b5e6605b9b8b44aa

# Set up Python environment
WORKDIR /workspace/repo

# Pre-install dependencies into system Python (cache layer)
RUN pip install --upgrade pip && \
    pip install setuptools && \
    pip install -e . && \
    pip uninstall -y pyarrow && \
    pip install "pyarrow==20.0.0" && \
    pip install pytest pytest-xdist

# Copy the runner script
COPY runner.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/runner.sh

ENTRYPOINT ["/usr/local/bin/runner.sh"]
