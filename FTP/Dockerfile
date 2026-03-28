FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Build dependencies for vsftpd
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpam0g-dev libcap-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Compile vsftpd 2.3.4 from source (CVE-2011-2523 — backdoor on port 6200)
COPY vsftpd/2ea5d19978710527bb7444d93b67767a-vsftpd-2.3.4.tar.gz /tmp/
RUN cd /tmp && tar xzf *.tar.gz \
    && cd vsftpd-2.3.4 \
    && echo "LIBS = -lcrypt -lpam -lcap -lssl" >> Makefile \
    && make -j$(nproc) \
    && cp vsftpd /usr/local/sbin/ \
    && cd / && rm -rf /tmp/*

# Create FTP user and directories
RUN useradd -r -d /var/ftp -s /usr/sbin/nologin ftp 2>/dev/null || true \
    && mkdir -p /var/ftp/pub /var/run/vsftpd/empty /etc/vsftpd \
    && chmod 755 /var/ftp && chmod 777 /var/ftp/pub

# Vulnerable config — anonymous access enabled
RUN printf 'listen=YES\n\
listen_port=21\n\
anonymous_enable=YES\n\
local_enable=YES\n\
write_enable=YES\n\
anon_upload_enable=YES\n\
anon_mkdir_write_enable=YES\n\
anon_root=/var/ftp\n\
secure_chroot_dir=/var/run/vsftpd/empty\n' > /etc/vsftpd.conf

# Copy exploit
COPY vsftpd/17491.rb /exploits/

EXPOSE 21 6200
CMD ["/usr/local/sbin/vsftpd", "/etc/vsftpd.conf"]
