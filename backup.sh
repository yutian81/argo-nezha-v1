#!/bin/sh

# 设置默认值
R2_ACCESS_KEY_ID=${R2_ACCESS_KEY_ID:-""}
R2_SECRET_ACCESS_KEY=${R2_SECRET_ACCESS_KEY:-""}
R2_ENDPOINT_URL=${R2_ENDPOINT_URL:-""}
R2_BUCKET_NAME=${R2_BUCKET_NAME:-""}

# 检查必要的环境变量
if [ -z "$R2_ACCESS_KEY_ID" ] || [ -z "$R2_SECRET_ACCESS_KEY" ] || [ -z "$R2_ENDPOINT_URL" ] || [ -z "$R2_BUCKET_NAME" ]; then
    echo "Warning: R2 environment variables are not set, skipping backup/restore"
    exit 0
fi

# R2配置
export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="auto"
export AWS_ENDPOINT_URL="$R2_ENDPOINT_URL"
export BUCKET_NAME="$R2_BUCKET_NAME"

# 恢复功能
restore_backup() {
    echo "Checking for latest backup in R2..."
    LATEST_BACKUP=$(aws s3 ls "s3://${BUCKET_NAME}/backups/nezha_backup_" | sort | tail -n 1 | awk '{print $4}' || echo "")
    
    if [ -n "$LATEST_BACKUP" ]; then
        echo "Found backup: ${LATEST_BACKUP}"
        echo "Downloading and restoring backup..."
        aws s3 cp "s3://${BUCKET_NAME}/backups/${LATEST_BACKUP}" /tmp/ || true
        if [ -f "/tmp/${LATEST_BACKUP}" ]; then
            rm -rf /dashboard/data/*
            cd /dashboard && tar -xzf "/tmp/${LATEST_BACKUP}"
            rm "/tmp/${LATEST_BACKUP}"
            echo "Backup restored successfully"
        else
            echo "Failed to download backup"
        fi
    else
        echo "No backup found in R2, starting with fresh data directory"
    fi
}

# 备份功能
create_backup() {
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="nezha_backup_${TIMESTAMP}.tar.gz"
    BACKUP_DIR="/tmp/nezha_backup_${TIMESTAMP}"

    # 创建备份目录
    mkdir -p "${BACKUP_DIR}/data"

    # 备份 SQLite 数据库
    echo "Backing up SQLite database..."
    sqlite3 "/dashboard/data/sqlite.db" "VACUUM INTO '${BACKUP_DIR}/data/sqlite.db'"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to backup SQLite database!"
        rm -rf "$BACKUP_DIR"
        return 1
    fi

    # 备份 config.yaml
    echo "Backing up config.yaml..."
    cp "/dashboard/data/config.yaml" "${BACKUP_DIR}/data/config.yaml"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to backup config.yaml!"
        rm -rf "$BACKUP_DIR"
        return 1
    fi

    # 压缩备份文件
    echo "Compressing backup files..."
    tar -czf "/tmp/${BACKUP_FILE}" -C "$BACKUP_DIR" .
    if [ $? -ne 0 ]; then
        echo "Error: Failed to compress backup files!"
        rm -rf "$BACKUP_DIR"
        return 1
    fi

    # 上传到 R2
    echo "Uploading backup to R2..."
    aws s3 cp "/tmp/${BACKUP_FILE}" "s3://${BUCKET_NAME}/backups/${BACKUP_FILE}"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to upload backup to R2!"
        rm "/tmp/${BACKUP_FILE}"
        rm -rf "$BACKUP_DIR"
        return 1
    fi

    # 清理临时文件
    rm "/tmp/${BACKUP_FILE}"
    rm -rf "$BACKUP_DIR"

    # 删除7天前的备份
    OLD_DATE=$(date -d "7 days ago" +%Y%m%d)
    echo "Cleaning up old backups before: $OLD_DATE"
    aws s3 ls "s3://${BUCKET_NAME}/backups/" | grep "nezha_backup_" | while read -r line; do
        backup_file=$(echo "$line" | awk '{print $4}')
        backup_date=$(echo "$backup_file" | grep -o "[0-9]\{8\}")
        if [ ! -z "$backup_date" ] && [ "$backup_date" -lt "$OLD_DATE" ]; then
            echo "Deleting old backup: $backup_file"
            aws s3 rm "s3://${BUCKET_NAME}/backups/$backup_file"
        fi
    done
    
    echo "Backup process completed successfully!"
}

# 根据参数执行不同的操作
case "$1" in
    "restore")
        restore_backup
        ;;
    "backup")
        create_backup
        ;;
    *)
        echo "Usage: $0 {backup|restore}"
        exit 1
        ;;
esac
