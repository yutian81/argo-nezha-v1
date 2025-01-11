#!/bin/sh
# 检查必要的环境变量
if [ -z "$R2_ACCESS_KEY_ID" ] || [ -z "$R2_SECRET_ACCESS_KEY" ] || [ -z "$R2_ENDPOINT_URL" ] || [ -z "$R2_BUCKET_NAME" ]; then
    echo "Warning: R2 environment variables are not set,skipping backup"
    exit 0
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
BACKUP_DIR="/tmp/nezha_backup_${TIMESTAMP}"

# 创建 /data 目录结构
mkdir -p "${BACKUP_DIR}/data"

# 备份 SQLite 数据库
echo "Backing up SQLite database..."
sqlite3 "/dashboard/data/sqlite.db" "VACUUM INTO '${BACKUP_DIR}/data/sqlite.db'"
if [ $? -ne 0 ]; then
    echo "Error: Failed to backup SQLite database!"
    rm -rf "$BACKUP_DIR"
    exit 1
fi

# 备份 config.yaml
echo "Backing up config.yaml..."
cp "/dashboard/data/config.yaml" "${BACKUP_DIR}/data/config.yaml"
if [ $? -ne 0 ]; then
    echo "Error: Failed to backup config.yaml!"
    rm -rf "$BACKUP_DIR"
    exit 1
fi

# 压缩备份文件
echo "Compressing backup files..."
tar -czf "/tmp/${BACKUP_FILE}" -C "$BACKUP_DIR" .
if [ $? -ne 0 ]; then
    echo "Error: Failed to compress backup files!"
    rm -rf "$BACKUP_DIR"
    exit 1
fi

# 上传到 R2
echo "Uploading backup to R2..."
aws s3 cp "/tmp/${BACKUP_FILE}" "s3://${BUCKET_NAME}/backups/${BACKUP_FILE}"
if [ $? -ne 0 ]; then
    echo "Error: Failed to upload backup to R2!"
    rm "/tmp/${BACKUP_FILE}"
    rm -rf "$BACKUP_DIR"
    exit 1
fi

# 清理临时文件
rm "/tmp/${BACKUP_FILE}"
rm -rf "$BACKUP_DIR"

# 删除7天前的备份
OLD_DATE=$(date -d "7 days ago" +%Y%m%d)
echo "Current date: $(date +%Y%m%d)"
echo "Old date threshold: $OLD_DATE"
aws s3 ls "s3://${BUCKET_NAME}/backups/" | grep "nezha_backup_" | while read -r line; do
    # 提取文件名
    backup_file=$(echo "$line" | awk '{print $4}')
    # 从文件名中提取日期部分 (YYYYMMDD)
    backup_date=$(echo "$backup_file" | grep -o "[0-9]\{8\}")
    echo "Processing file: $backup_file"
    echo "Extracted date: $backup_date"
    if [ ! -z "$backup_date" ]; then
        echo "Comparing dates: $backup_date vs $OLD_DATE"
        if [ "$backup_date" -lt "$OLD_DATE" ]; then
            echo "Deleting old backup: $backup_file"
            aws s3 rm "s3://${BUCKET_NAME}/backups/$backup_file"
        else
            echo "Keeping backup: $backup_file"
        fi
    else
        echo "Could not extract date from: $backup_file"
    fi
done
echo "Backup process completed successfully!"
