#!/bin/sh

# 检查必要的环境变量
if [ -z "$R2_ACCESS_KEY_ID" ] || [ -z "$R2_SECRET_ACCESS_KEY" ] || [ -z "$R2_ENDPOINT_URL" ] || [ -z "$R2_BUCKET_NAME" ]; then
    echo "Warning: R2 environment variables are not set, skipping backup/restore"
else
    # 配置R2环境变量
    export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
    export AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
    export AWS_DEFAULT_REGION="auto"
    export AWS_ENDPOINT_URL="$R2_ENDPOINT_URL"
    export BUCKET_NAME="$R2_BUCKET_NAME"

    # 尝试从R2恢复最新备份
    echo "Checking for latest backup in R2..."
    LATEST_BACKUP=$(aws s3 ls "s3://${BUCKET_NAME}/backups/nezha_backup_" | sort | tail -n 1 | awk '{print $4}')

    if [ ! -z "$LATEST_BACKUP" ]; then
        echo "Found backup: ${LATEST_BACKUP}"
        echo "Downloading and restoring backup..."
        aws s3 cp "s3://${BUCKET_NAME}/backups/${LATEST_BACKUP}" /tmp/
        rm -rf /dashboard/data/*
        cd /dashboard && tar -xzf "/tmp/${LATEST_BACKUP}"
        rm "/tmp/${LATEST_BACKUP}"
        echo "Backup restored successfully"
    else
        echo "No backup found in R2, starting with fresh data directory"
    fi
fi

# 启动 crond 服务
echo "Starting crond ..."
crond

# 设置 agent 上报 tls: true
sed -i'' 's|tls: false|tls: true|g' /dashboard/data/config.yaml

# 启动 dashboard app
echo "Starting dashboard app..."
/dashboard/app &

openssl genrsa -out /dashboard/nezha.key 2048
openssl req -new -subj "/CN=$ARGO_DOMAIN" -key /dashboard/nezha.key -out /dashboard/nezha.csr
openssl x509 -req -days 36500 -in /dashboard/nezha.csr -signkey /dashboard/nezha.key -out /dashboard/nezha.pem

sleep 3

# 启动 Nginx
echo "Starting nginx..."
nginx -g "daemon off;" &

openssl s_client -connect localhost:443

sleep 5

# 启动 cloudflared 隧道
if [ -z "$CF_TOKEN" ]; then
    echo "Error: CF_TOKEN is not set"
    exit 1
fi

echo "Starting cloudflared..."
cloudflared --no-autoupdate tunnel run --protocol http2 --token "$CF_TOKEN" &

# 等待所有后台进程
wait
