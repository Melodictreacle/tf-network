FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Build dependencies for Samba 3.5.0 (no CUPS to avoid deprecation errors)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libldap2-dev libpopt-dev libreadline-dev \
    python2 pkg-config libacl1-dev libattr1-dev \
    && ln -sf /usr/bin/python2 /usr/bin/python 2>/dev/null || true \
    && rm -rf /var/lib/apt/lists/*

# Compile Samba 3.5.0 from source (CVE-2017-7494 — SambaCry)
COPY samba/05e389aff7d3de16561006b35332a881-samba-3.5.0.tar.gz /tmp/
RUN cd /tmp && tar xzf *.tar.gz \
    && cd samba-3.5.0/source3 \
    && CFLAGS="-Wno-error=deprecated-declarations" \
       ./configure --prefix=/usr/local/samba \
        --disable-cups --without-ads --without-krb5 \
        --without-ldap --without-pam \
    && CFLAGS="-Wno-error=deprecated-declarations -Wno-error" \
       make -j$(nproc) || make -j1 \
    && make install \
    && echo "/usr/local/samba/lib" > /etc/ld.so.conf.d/samba.conf \
    && ldconfig \
    && cd / && rm -rf /tmp/*

# Create share directory
RUN mkdir -p /srv/samba/share && chmod 777 /srv/samba/share \
    && mkdir -p /usr/local/samba/var/log/samba \
    && mkdir -p /usr/local/samba/etc

# Vulnerable config — writable anonymous share
RUN printf '[global]\n\
workgroup = VULNLAB\n\
server string = Vulnerable Samba\n\
map to guest = Bad User\n\
log file = /usr/local/samba/var/log/samba/%%m.log\n\
max log size = 50\n\
\n\
[public]\n\
path = /srv/samba/share\n\
browseable = yes\n\
writable = yes\n\
guest ok = yes\n\
create mask = 0777\n\
directory mask = 0777\n' > /usr/local/samba/etc/smb.conf

# Copy exploit
COPY samba/42060.py /exploits/

EXPOSE 139 445
CMD sh -c "/usr/local/samba/sbin/smbd --foreground --no-process-group -s /usr/local/samba/etc/smb.conf & /usr/local/samba/sbin/nmbd --foreground --no-process-group -s /usr/local/samba/etc/smb.conf & tail -f /dev/null"
