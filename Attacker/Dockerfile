FROM kalilinux/kali-rolling:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install required tools for lab exploitation and verification
RUN apt-get update && apt-get install -y \
    netcat-traditional \
    iputils-ping \
    smbclient \
    rsync \
    dnsutils \
    nmap \
    python3 \
    ldap-utils \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Keep container running indefinitely
CMD ["sleep", "infinity"]
