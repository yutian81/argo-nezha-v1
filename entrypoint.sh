#!/bin/sh

# 启动 Cloudflared 隧道
echo "Starting Cloudflared tunnel..."
cloudflared tunnel --no-autoupdate run --token $CF_TOKEN &
cf_pid=$!

# 启动 Caddy 2
echo "Starting Caddy 2..."
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
caddy_pid=$!

# 启动 /dashboard/app
echo "Starting Dashboard app..."
/dashboard/app &
app_pid=$!

# 等待所有后台进程完成
wait $cf_pid $caddy_pid $app_pid
