FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Build dependencies for OpenLDAP (using MDB backend instead of BDB)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libssl-dev groff-base \
    && rm -rf /var/lib/apt/lists/*

# Compile OpenLDAP 2.4.18 from source (Config Flaw — null DN auth bypass)
COPY openldap/openldap-2.4.18.tgz /tmp/
RUN cd /tmp && tar xzf *.tgz \
    && cd openldap-2.4.18 \
    && ./configure --prefix=/usr/local/openldap \
        --enable-slapd --enable-ldap \
        --disable-bdb --disable-hdb \
    && make depend \
    && make -j$(nproc) \
    && make install \
    && cd / && rm -rf /tmp/*

# Create required directories
RUN mkdir -p /usr/local/openldap/var/run \
    /usr/local/openldap/var/openldap-data

# Vulnerable config — allows anonymous/null DN bind (uses LDIF backend)
RUN printf 'include /usr/local/openldap/etc/openldap/schema/core.schema\n\
pidfile /usr/local/openldap/var/run/slapd.pid\n\
argsfile /usr/local/openldap/var/run/slapd.args\n\
database ldif\n\
suffix "dc=vuln-lab,dc=local"\n\
rootdn "cn=admin,dc=vuln-lab,dc=local"\n\
rootpw admin123\n\
directory /usr/local/openldap/var/openldap-data\n\
access to * by * read\n' > /usr/local/openldap/etc/openldap/slapd.conf

EXPOSE 389
CMD ["/usr/local/openldap/libexec/slapd", "-d", "256", "-h", "ldap://0.0.0.0:389/"]
