#!/bin/sh

# 检查必要的环境变量
if [ -z "$R2_ACCESS_KEY_ID" ] || [ -z "$R2_SECRET_ACCESS_KEY" ] || [ -z "$R2_ENDPOINT_URL" ] || [ -z "$R2_BUCKET_NAME" ]; then
    echo "Error: Required environment variables are not set"
    echo "Please ensure R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_ENDPOINT_URL, and R2_BUCKET_NAME are set"
    exit 1
fi

# R2配置
export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="auto"
export AWS_ENDPOINT_URL="$R2_ENDPOINT_URL"
export BUCKET_NAME="$R2_BUCKET_NAME"

# 创建备份
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="nezha_backup_${TIMESTAMP}.tar.gz"

# 压缩数据
cd /dashboard && tar -czf "/tmp/${BACKUP_FILE}" data/

# 上传到R2
aws s3 cp "/tmp/${BACKUP_FILE}" "s3://${BUCKET_NAME}/backups/${BACKUP_FILE}"

# 删除本地临时文件
rm "/tmp/${BACKUP_FILE}"

# 删除7天前的备份
OLD_DATE=$(date -d "7 days ago" +%Y%m%d)
aws s3 ls "s3://${BUCKET_NAME}/backups/" | grep "nezha_backup_" | while read -r line; do
    # 提取文件名
    backup_file=$(echo "$line" | awk '{print $4}')
    # 提取日期部分 YYYYMMDD
    backup_date=$(echo "$backup_file" | cut -d'_' -f3)
    # 比较日期
    if [ "$backup_date" -le "$OLD_DATE" ]; then
        echo "Deleting old backup: $backup_file"
        aws s3 rm "s3://${BUCKET_NAME}/backups/$backup_file"
    fi
done
