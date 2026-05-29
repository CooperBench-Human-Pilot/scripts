FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    libsndfile1-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone the repository and checkout the specific commit
WORKDIR /workspace
RUN git clone https://github.com/stanfordnlp/dspy.git repo && \
    cd repo && \
    git checkout 8f773dc75e34da21b89480e8bc71df503d5ab5fc

# Install Python dependencies
WORKDIR /workspace/repo
RUN pip install --upgrade pip && \
    pip install -e ".[dev]"

# Copy the runner script
COPY runner.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/runner.sh

ENTRYPOINT ["/usr/local/bin/runner.sh"]
