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
RUN git clone https://github.com/pallets/jinja.git repo && \
    cd repo && \
    git checkout a2920752fd111c2d52c88eb57487667b3cf0ea7b

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

