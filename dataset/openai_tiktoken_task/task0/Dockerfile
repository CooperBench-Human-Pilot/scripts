FROM python:3.11-slim

# Install system dependencies including Rust
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Clone the repository and checkout the specific commit
WORKDIR /workspace
RUN git clone https://github.com/openai/tiktoken repo && \
    cd repo && \
    git checkout 4560a8896f5fb1d35c6f8fd6eee0399f9a1a27ca

# Install Python dependencies
WORKDIR /workspace/repo
RUN pip install --upgrade pip && \
    pip install -e . && \
    pip install pytest pytest-xdist regex hypothesis

# Copy the runner script
COPY runner.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/runner.sh

ENTRYPOINT ["/usr/local/bin/runner.sh"]
