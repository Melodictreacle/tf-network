FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Install SSH, NFS and build deps for rsync
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpopt-dev openssh-server nfs-kernel-server \
    && rm -rf /var/lib/apt/lists/*

# Compile rsync 3.1.1 from source (CVE-2014-9512 — path traversal)
COPY rsync/rsync-3.1.1.tar.gz /tmp/
RUN cd /tmp && tar xzf *.tar.gz \
    && cd rsync-3.1.1 \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && cd / && rm -rf /tmp/*

# SSH — weak config for lab
RUN mkdir -p /run/sshd \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo 'root:backup123' | chpasswd

# rsync — open daemon (CVE-2014-9512)
RUN mkdir -p /srv/backup \
    && printf '[backup]\n\
path = /srv/backup\n\
comment = Backup share\n\
read only = no\n\
auth users = \n\
uid = root\n\
gid = root\n' > /etc/rsyncd.conf

# NFS — no_root_squash (Config Flaw)
RUN mkdir -p /srv/nfs/share && chmod 777 /srv/nfs/share \
    && echo "/srv/nfs/share *(rw,sync,no_subtree_check,no_root_squash)" > /etc/exports

EXPOSE 22 873 2049
CMD sh -c "/usr/sbin/sshd; rsync --daemon; exportfs -ra 2>/dev/null; rpc.nfsd 2>/dev/null; tail -f /dev/null"
