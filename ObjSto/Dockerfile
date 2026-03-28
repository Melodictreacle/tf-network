FROM ubuntu:20.04 AS minio-builder
ENV DEBIAN_FRONTEND=noninteractive

# Install Go for compiling MinIO
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget ca-certificates gcc libc6-dev \
    && wget -q https://go.dev/dl/go1.20.14.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.20.14.linux-amd64.tar.gz \
    && rm go1.20.14.linux-amd64.tar.gz \
    && rm -rf /var/lib/apt/lists/*
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/go"

# Compile MinIO from source (CVE-2023-28432)
COPY minio/minio-RELEASE.2023-03-13T19-46-17Z.tar.gz /tmp/
RUN cd /tmp && tar xzf *.tar.gz \
    && cd minio-* \
    && go build -o /usr/local/bin/minio . \
    && chmod +x /usr/local/bin/minio

# ---- Runtime stage ----
FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Install MariaDB + Redis (storage backend for OwnCloud)
RUN apt-get update && apt-get install -y --no-install-recommends \
    mariadb-server redis-server \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled MinIO binary from builder
COPY --from=minio-builder /usr/local/bin/minio /usr/local/bin/minio

# MariaDB — allow remote connections from Host F
RUN sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

# Redis — listen on all interfaces
RUN sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf 2>/dev/null || true \
    && sed -i 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf 2>/dev/null || true

# Startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Create MinIO data dir
RUN mkdir -p /data/minio

EXPOSE 3306 6379 9000 9001
CMD ["/bin/bash", "/start.sh"]
