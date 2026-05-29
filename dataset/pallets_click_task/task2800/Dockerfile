FROM python:3.11-slim

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
RUN git clone https://github.com/pallets/click.git repo && \
    cd repo && \
    git checkout d8763b93021c416549b5f8b4b5497234619410db

# Set up Python environment
WORKDIR /workspace/repo

# Pre-install dependencies into system Python (cache layer)
RUN pip install --upgrade pip && \
    pip install -e ".[test]" || pip install -e . && \
    pip install pytest pytest-xdist pytest_mock

# Copy the runner script
COPY runner.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/runner.sh

ENTRYPOINT ["/usr/local/bin/runner.sh"]

