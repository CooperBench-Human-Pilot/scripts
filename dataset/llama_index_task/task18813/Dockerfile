FROM python:3.10-slim

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
RUN git clone https://github.com/run-llama/llama_index.git repo && \
    cd repo && \
    git checkout 5eca4973cef04eca5d817d3e1515c8cbe7d1cf9e

# Set up Python environment and pre-install dependencies
WORKDIR /workspace/repo
RUN uv pip install --system -r pyproject.toml || uv pip install --system -e .
RUN uv pip install --system pytest pytest-xdist pytest-asyncio openai

# Copy the runner script
COPY runner.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/runner.sh

ENTRYPOINT ["/usr/local/bin/runner.sh"]

