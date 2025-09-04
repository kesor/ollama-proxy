#!/bin/sh

if [ -z "$CLOUDFLARE_TUNNEL_TOKEN" ]; then
    echo "Error: CLOUDFLARE_TUNNEL_TOKEN is not set."
    exit 1
fi

/check-cloudflared-update.sh

/usr/bin/nohup cloudflared --no-autoupdate tunnel run --token "${CLOUDFLARE_TUNNEL_TOKEN}" >/dev/stdout 2>/dev/stderr &
