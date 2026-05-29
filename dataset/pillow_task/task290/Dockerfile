FROM python:3.11-slim

# Install system dependencies for Pillow
RUN apt-get update && apt-get install -y \
    git \
    libjpeg-dev \
    zlib1g-dev \
    libpng-dev \
    libtiff-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libopenjp2-7-dev \
    libwebp-dev \
    tcl8.6-dev \
    tk8.6-dev \
    python3-tk \
    && rm -rf /var/lib/apt/lists/*

# Clone the repository and checkout the specific commit
WORKDIR /workspace
RUN git clone https://github.com/python-pillow/Pillow.git repo && \
    cd repo && \
    git checkout cc927343dadc4d5c53afebba9c41fe02b6d7bbe4

# Install Python dependencies
WORKDIR /workspace/repo
RUN pip install --upgrade pip && \
    pip install -e . && \
    pip install pytest pytest-xdist numpy

# Copy the runner script
COPY runner.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/runner.sh

ENTRYPOINT ["/usr/local/bin/runner.sh"]
