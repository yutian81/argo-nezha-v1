#!/bin/sh

# 检查 nginx 配置
echo "Testing nginx configuration..."
nginx -t

# 启动 Nginx
echo "Starting nginx..."
nginx -g "daemon off;" &
nginx_pid=$!

# 启动 cloudflared 隧道
echo "Starting cloudflared..."
cloudflared tunnel --no-autoupdate run --token $CF_TOKEN &
cf_pid=$!

# 启动 /dashboard/app
echo "Starting dashboard app..."
exec /dashboard/app &
app_pid=$!

# 等待所有后台进程完成
wait $cf_pid $nginx_pid $app_pid
