FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Install BIND9 from apt + build deps for Squid (including ltdl)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libssl-dev pkg-config autoconf automake libtool \
    libltdl-dev \
    bind9 bind9utils \
    && rm -rf /var/lib/apt/lists/*

# Compile Squid 5.0.1 from source (CVE-2020-11945 — cache poisoning)
COPY squid/squid-SQUID_5_0_1.tar.gz /tmp/
RUN cd /tmp && tar xzf *.tar.gz \
    && cd squid-* \
    && ([ -f bootstrap.sh ] && sh bootstrap.sh || true) \
    && ([ -f configure ] || autoreconf -fi 2>&1 || true) \
    && ./configure --prefix=/usr/local/squid \
        --with-openssl --disable-arch-native \
    && make -j$(nproc) \
    && make install \
    && cd / && rm -rf /tmp/*

# Create Squid runtime dirs and user
RUN useradd -r -s /usr/sbin/nologin squid 2>/dev/null || true \
    && mkdir -p /usr/local/squid/var/cache \
        /usr/local/squid/var/logs \
        /usr/local/squid/var/run \
    && chown -R squid:squid /usr/local/squid/var 2>/dev/null || true

# BIND9 — allow unrestricted zone transfers (Config Flaw)
RUN printf 'options {\n\
  directory "/var/cache/bind";\n\
  recursion yes;\n\
  allow-query { any; };\n\
  allow-transfer { any; };\n\
  allow-recursion { any; };\n\
  forwarders { 8.8.8.8; 8.8.4.4; };\n\
  dnssec-validation no;\n\
  listen-on { any; };\n\
};\n' > /etc/bind/named.conf.options

# Squid — permissive proxy
RUN printf 'http_port 3128\n\
acl all src 0.0.0.0/0\n\
http_access allow all\n' > /usr/local/squid/etc/squid.conf

# Startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 53/udp 53/tcp 3128
CMD ["/bin/bash", "/start.sh"]
