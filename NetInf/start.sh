#!/bin/bash
set -e

# Start BIND9
named -u bind 2>/dev/null || true
echo "BIND9 started."

# Start Squid
if [ -x /usr/local/squid/sbin/squid ]; then
    /usr/local/squid/sbin/squid -N &
    echo "Squid started."
else
    echo "Squid binary not found — skipping."
fi

# Keep container alive
tail -f /dev/null
