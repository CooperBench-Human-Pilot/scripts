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
    git checkout 3ded7a6266514c1569452b0e26bcd4e75c1ee6db

# Install Python dependencies
WORKDIR /workspace/repo
RUN pip install --upgrade pip && \
    pip install -e ".[dev]"

# Copy the runner script
COPY runner.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/runner.sh

ENTRYPOINT ["/usr/local/bin/runner.sh"]
