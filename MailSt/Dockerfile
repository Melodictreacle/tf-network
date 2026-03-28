FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Install Postfix and Dovecot
RUN echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections \
    && echo "postfix postfix/mailname string vuln-lab.local" | debconf-set-selections \
    && apt-get update && apt-get install -y --no-install-recommends \
    postfix dovecot-imapd dovecot-pop3d \
    && rm -rf /var/lib/apt/lists/*

# Copy VDA patch for reference
COPY postfix/postfix-2.5.6-vda-ng.patch.gz /exploits/

# Postfix — open relay config (CVE-2011-1720 context)
RUN postconf -e "inet_interfaces = all" \
    && postconf -e "mynetworks = 0.0.0.0/0" \
    && postconf -e "smtpd_recipient_restrictions = permit"

# Dovecot — plaintext auth, no SSL (Config Flaw)
RUN sed -i 's/#disable_plaintext_auth = yes/disable_plaintext_auth = no/' \
        /etc/dovecot/conf.d/10-auth.conf 2>/dev/null || true \
    && sed -i 's/ssl = required/ssl = no/' \
        /etc/dovecot/conf.d/10-ssl.conf 2>/dev/null || true

EXPOSE 25 143 110

CMD sh -c "postfix start; dovecot; tail -f /dev/null"
