#!/bin/sh
# 检查 nginx 配置
echo "Testing nginx configuration..."
nginx -t

# 启动 dashboard app
echo "Starting dashboard app..."
/dashboard/app &

# 等待几秒钟确保 app 启动
sleep 5

# 启动 Nginx
echo "Starting nginx..."
nginx -g "daemon off;" &

# 启动 cloudflared 隧道
echo "Starting cloudflared..."
cloudflared tunnel --no-autoupdate run --token $CF_TOKEN &

# 等待所有后台进程
wait
