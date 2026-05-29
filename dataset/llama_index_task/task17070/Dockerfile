FROM python:3.10-slim

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
RUN git clone https://github.com/run-llama/llama_index.git repo && \
    cd repo && \
    git checkout 0417380ada935e277d686aef941b84032e67c57a

# Set up Python environment
WORKDIR /workspace/repo

# Pre-install dependencies into system Python (cache layer)
RUN pip install --upgrade pip && \
    pip install -e ./llama-index-core && \
    pip install pytest pytest-xdist openai

# Copy the runner script
COPY runner.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/runner.sh

ENTRYPOINT ["/usr/local/bin/runner.sh"]

