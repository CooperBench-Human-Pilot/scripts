FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install uv (modern Python package manager)
RUN pip install uv

# Clone the repository and checkout the specific commit
WORKDIR /workspace
RUN git clone https://github.com/dottxt-ai/outlines.git repo && \
    cd repo && \
    git checkout 7149a5e613b9c2bb3c2ed3ee5b7c9228772504b1

# Set up Python environment
WORKDIR /workspace/repo

# Pre-install dependencies into system Python (cache layer)
RUN uv pip install --system -e ".[test]" || uv pip install --system -e .
RUN uv pip install --system pytest pytest-xdist pytest_mock

# Copy the runner script
COPY runner.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/runner.sh

ENTRYPOINT ["/usr/local/bin/runner.sh"]
