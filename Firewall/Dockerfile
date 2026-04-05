FROM alpine:3.14

# Install networking tools + OpenSSH
RUN apk add --no-cache \
    openssh \
    iptables \
    iproute2 \
    iputils \
    bash \
    curl \
    net-tools \
    tcpdump

# Configure SSH with WEAK credentials (intentionally vulnerable)
# Vulnerability: default root password "toor" — Config Flaw
RUN echo "root:toor" | chpasswd

# Generate host keys
RUN ssh-keygen -A

# Allow root login with password (insecure config)
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# Copy entrypoint
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 22

CMD ["/start.sh"]
