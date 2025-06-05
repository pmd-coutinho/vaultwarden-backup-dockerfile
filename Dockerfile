FROM alpine:latest

# Install required packages
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    unzip \
    tzdata \
    docker-cli

# Install rclone
RUN curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
    unzip rclone-current-linux-amd64.zip && \
    cd rclone-*-linux-amd64 && \
    cp rclone /usr/bin/ && \
    chmod 755 /usr/bin/rclone && \
    cd .. && \
    rm -rf rclone-*

# Create backup directory
RUN mkdir -p /backup

# Copy backup script
COPY backup.sh /backup/backup.sh
RUN chmod +x /backup/backup.sh

# Set working directory
WORKDIR /backup

# Set entrypoint
ENTRYPOINT ["/backup/backup.sh"]
