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
    git checkout 4dd7802a8a5021f31dac75bc652f88d410a28675

# Set up Python environment and pre-install dependencies
WORKDIR /workspace/repo
RUN uv pip install --system -e ".[test]" || uv pip install --system -e .
RUN uv pip install --system pytest pytest-xdist pytest_mock

# Copy the runner script
COPY runner.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/runner.sh

ENTRYPOINT ["/usr/local/bin/runner.sh"]

