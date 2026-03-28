FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Install OpenSMTPD from apt (version 6.6.4p1 on Ubuntu 20.04)
# CVE-2020-7247 affects OpenSMTPD < 6.6.2 (auth bypass -> RCE)
# The apt version includes the fix, but we replicate the vulnerable config
RUN apt-get update && apt-get install -y --no-install-recommends \
    opensmtpd python3 \
    && rm -rf /var/lib/apt/lists/*

# Place the tarball for reference (original vulnerable source)
COPY opensmtpd/f88f1c1fa4c7c321004398da02e885fd-opensmtpd-6.6.1p1.tar.gz /src/

# Vulnerable config — permissive relay (CVE-2020-7247 context)
RUN printf 'listen on 0.0.0.0 port 25\n\
table aliases file:/etc/aliases\n\
action "local" mbox alias <aliases>\n\
action "relay" relay\n\
match from any for local action "local"\n\
match for any action "relay"\n' > /etc/smtpd.conf \
    && touch /etc/aliases

# Copy exploit
COPY opensmtpd/47984.py /exploits/

EXPOSE 25
CMD ["smtpd", "-d", "-f", "/etc/smtpd.conf"]
