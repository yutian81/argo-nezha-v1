#!/bin/sh

# 启动 Cloudflared 隧道
cloudflared tunnel --no-autoupdate run --token $CF_TOKEN &

# 启动 Caddy 2
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &

# 启动 /dashboard/app
exec /dashboard/app
