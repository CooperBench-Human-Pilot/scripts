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
    git checkout 80412ce96d70fdb64dcf2c63940f511d6f89ca44

# Install Python dependencies
WORKDIR /workspace/repo
RUN pip install --upgrade pip && \
    pip install -e ".[dev]"

# Copy the runner script
COPY runner.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/runner.sh

ENTRYPOINT ["/usr/local/bin/runner.sh"]
