#!/bin/sh

# 设置默认值
ARGO_DOMAIN=${ARGO_DOMAIN:-""}
CF_TOKEN=${CF_TOKEN:-""}

# 配置定时备份任务（北京时间每天凌晨2点）
echo "设置自动备份任务"
echo "0 2 * * * /backup.sh backup >> /dashboard/backup.log 2>&1" > /var/spool/cron/crontabs/root
/backup.sh restore # 尝试恢复备份
echo "正在启动 crond"  # 启动 crond
crond

# 启动 dashboard app
echo "正在启动哪吒面板"
/dashboard/app &
sleep 3

# 检查并生成证书
if [ -n "$ARGO_DOMAIN" ]; then
    echo "正在生成域名证书: $ARGO_DOMAIN"
    openssl genrsa -out /dashboard/nezha.key 2048
    openssl req -new -subj "/CN=$ARGO_DOMAIN" -key /dashboard/nezha.key -out /dashboard/nezha.csr
    openssl x509 -req -days 36500 -in /dashboard/nezha.csr -signkey /dashboard/nezha.key -out /dashboard/nezha.pem
else
    echo "警告: 未设置ARGO_DOMAIN，正在跳过证书生成"
fi

# 启动 Nginx
echo "正在启动 nginx..."
nginx -g "daemon off;" &
sleep 3

# 启动 cloudflared
if [ -n "$CF_TOKEN" ]; then
    echo "正在启动 cloudflared..."
    cloudflared --no-autoupdate tunnel run --protocol http2 --token "$CF_TOKEN" &
else
    echo "警告: 未设置CF_TOKEN，正在跳过执行 cloudflared"
fi

# 等待所有后台进程
wait
