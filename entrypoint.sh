#!/bin/sh

# 设置默认值
ARGO_DOMAIN=${ARGO_DOMAIN:-""}
CF_TOKEN=${CF_TOKEN:-""}

# 配置定时备份任务
echo "Setting up backup cron job..."
echo "0 2,14 * * * /backup.sh backup >> /dashboard/backup.log 2>&1" > /var/spool/cron/crontabs/root

# 尝试恢复备份
/backup.sh restore

# 启动 crond
echo "Starting crond ..."
crond

# 启动 dashboard app
echo "Starting dashboard app..."
/dashboard/app &
sleep 3

# 检查并生成证书
if [ -n "$ARGO_DOMAIN" ]; then
    echo "Generating certificate for domain: $ARGO_DOMAIN"
    openssl genrsa -out /dashboard/nezha.key 2048
    openssl req -new -subj "/CN=$ARGO_DOMAIN" -key /dashboard/nezha.key -out /dashboard/nezha.csr
    openssl x509 -req -days 36500 -in /dashboard/nezha.csr -signkey /dashboard/nezha.key -out /dashboard/nezha.pem
else
    echo "Warning: ARGO_DOMAIN is not set, skipping certificate generation"
fi

# 启动 Nginx
echo "Starting nginx..."
nginx -g "daemon off;" &
sleep 3

# 启动 cloudflared
if [ -n "$CF_TOKEN" ]; then
    echo "Starting cloudflared..."
    cloudflared --no-autoupdate tunnel run --protocol http2 --token "$CF_TOKEN" &
else
    echo "Warning: CF_TOKEN is not set, skipping cloudflared"
fi

# 等待所有后台进程
wait
