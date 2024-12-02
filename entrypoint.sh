#!/bin/sh

# 启动 Cloudflared 隧道
cloudflared tunnel --no-autoupdate run --token $CF_TOKEN &

# 启动 Caddy 2
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &

# 启动 /dashboard/app
printf "nameserver 127.0.0.11\nnameserver 8.8.4.4\nnameserver 223.5.5.5\n" > /etc/resolv.conf
exec /dashboard/app
