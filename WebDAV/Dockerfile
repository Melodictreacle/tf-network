FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Build dependencies for Apache httpd
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libapr1-dev libaprutil1-dev libpcre3-dev \
    && rm -rf /var/lib/apt/lists/*

# Compile Apache httpd 2.4.49 from source (CVE-2021-41773 — path traversal RCE)
COPY httpd/1edb1895661473ea530209e29b83a982-httpd-2.4.49.tar.gz /tmp/
RUN cd /tmp && tar xzf *.tar.gz \
    && cd httpd-2.4.49 \
    && ./configure --prefix=/usr/local/apache2 \
        --enable-so --enable-modules=most \
        --enable-cgi --enable-cgid \
        --enable-mpms-shared=all \
    && make -j$(nproc) \
    && make install \
    && cd / && rm -rf /tmp/*

# Make the default config vulnerable (CVE-2021-41773):
# 1. Enable CGI module
# 2. Set root Directory to "Require all granted" (permissive)
RUN sed -i 's|#LoadModule cgid_module|LoadModule cgid_module|' /usr/local/apache2/conf/httpd.conf \
    && sed -i 's|#LoadModule cgi_module|LoadModule cgi_module|' /usr/local/apache2/conf/httpd.conf \
    && sed -i 's|Require all denied|Require all granted|g' /usr/local/apache2/conf/httpd.conf \
    && sed -i 's|#ServerName www.example.com:80|ServerName localhost|' /usr/local/apache2/conf/httpd.conf

# Copy exploit
COPY httpd/50383.sh /exploits/

EXPOSE 80
CMD ["/usr/local/apache2/bin/httpd", "-D", "FOREGROUND"]
