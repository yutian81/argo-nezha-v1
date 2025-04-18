#!/bin/sh

# 设置默认值
GITHUB_TOKEN=${GITHUB_TOKEN:-""}
GITHUB_REPO_OWNER=${GITHUB_REPO_OWNER:-""}
GITHUB_REPO_NAME=${GITHUB_REPO_NAME:-""}
BACKUP_BRANCH=${BACKUP_BRANCH:-"nezha-v1"}

# 检查必要的环境变量
if [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_REPO_OWNER" ] || [ -z "$GITHUB_REPO_NAME" ]; then
    echo "警告: 未设置GitHub环境变量，正在跳过备份/还原"
    exit 0
fi

# GitHub配置
export GIT_AUTHOR_NAME="[Auto] DB Backup"
export GIT_AUTHOR_EMAIL="backup@nezhav1.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

# 临时目录
TEMP_DIR=$(mktemp -d)

# 恢复功能
restore_backup() {
    echo "正在检查GitHub repo中的最新备份"
    # 获取最新的备份提交
    LATEST_BACKUP_COMMIT=$(git ls-remote --heads "https://$GITHUB_TOKEN@github.com/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME.git" "$BACKUP_BRANCH" | awk '{print $1}')
    
    if [ -n "$LATEST_BACKUP_COMMIT" ]; then
        echo "找到备份提交: ${LATEST_BACKUP_COMMIT}"
        echo "正在下载并还原备份"
        git clone --branch "$BACKUP_BRANCH" --single-branch "https://$GITHUB_TOKEN@github.com/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME.git" "$TEMP_DIR/backup_repo" || true
        if [ -d "$TEMP_DIR/backup_repo" ]; then
            echo "正在从备份恢复数据..."
            mkdir -p dashboard/
            rm -f dashboard/sqlite.db
            cp "$TEMP_DIR/backup_repo/dashboard/sqlite.db" dashboard/
            if [ -f "$TEMP_DIR/backup_repo/dashboard/config.yaml" ]; then
                cp "$TEMP_DIR/backup_repo/dashboard/config.yaml" dashboard/
            fi
            echo "备份已成功恢复"
        else
            echo "无法克隆备份仓库"
        fi
    else
        echo "在GitHub repo中找不到备份，正在从新的数据目录开始"
    fi
    
    # 清理临时目录
    rm -rf "$TEMP_DIR/backup_repo"
}

# 备份功能
create_backup() {
    export TZ=Asia/Shanghai
    TIMESTAMP=$(date +'%Y%m%d-%H%M%S')
    COMMIT_TIME=$(date +'%Y-%m-%d %H:%M:%S %Z')
    BACKUP_DIR="$TEMP_DIR/backup_$TIMESTAMP"
    mkdir -p "$BACKUP_DIR/dashboard"
    
    # 检查数据库文件是否存在
    if [ ! -f "dashboard/sqlite.db" ]; then
        echo "错误: 数据库文件 dashboard/sqlite.db 不存在"
        rm -rf "$BACKUP_DIR"
        return 1
    fi
    
    echo "正在备份SQLite数据库..."
    sqlite3 "dashboard/sqlite.db" "VACUUM INTO '$BACKUP_DIR/dashboard/sqlite.db'"
    if [ $? -ne 0 ]; then
        echo "错误: 备份SQLite数据库失败"
        rm -rf "$BACKUP_DIR"
        return 1
    fi
    
    # 备份 config.yaml
    if [ -f "dashboard/config.yaml" ]; then
        echo "正在备份config.yaml"
        cp "dashboard/config.yaml" "$BACKUP_DIR/dashboard/config.yaml" || {
            echo "警告: 备份config.yaml失败" # 不因config.yaml备份失败而终止整个备份
        }
    fi
    
    # 初始化Git仓库并提交
    echo "正在创建Git备份"
    git init "$BACKUP_DIR"
    cd "$BACKUP_DIR" || return 1
    git remote add origin "https://$GITHUB_TOKEN@github.com/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME.git"
    git checkout -b "$BACKUP_BRANCH"
    git add .
    git commit -m "nezha-v1 Backup $COMMIT_TIME"
    
    # 推送到GitHub
    echo "正在推送备份到GitHub..."
    git push --force origin "$BACKUP_BRANCH"
    if [ $? -ne 0 ]; then
        echo "错误: 推送备份到GitHub失败"
        cd - || return 1
        rm -rf "$BACKUP_DIR"
        return 1
    fi
    
    # 清理7天前的备份文件（单分支模式）
    echo "正在清理7天前的旧备份文件"
    OLD_DATE=$(date -d "7 days ago" +%Y%m%d)
    
    # 克隆当前备份分支到临时目录
    CLEANUP_DIR="$TEMP_DIR/cleanup_repo"
    git clone --branch "$BACKUP_BRANCH" --single-branch "https://$GITHUB_TOKEN@github.com/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME.git" "$CLEANUP_DIR" || return 1
    cd "$CLEANUP_DIR" || return 1
    
    # 修改查找路径为 dashboard
    find dashboard -type f -name "*.*" | while read file; do
        file_date=$(stat -c %y "$file" | cut -d' ' -f1 | tr -d '-')
        if [ ! -z "$file_date" ] && [ "$file_date" -lt "$OLD_DATE" ]; then
            git rm "$file"
            echo "已删除旧备份文件: $file (修改日期: $file_date)"
        fi
    done
    
    # 如果有文件被删除，则提交更改
    if [ -n "$(git status --porcelain)" ]; then
        git commit -m "清理7天前的旧备份文件"
        git push origin "$BACKUP_BRANCH"
        echo "已清理旧备份文件并更新分支"
    else
        echo "没有需要清理的旧备份文件"
    fi
    
    # 清理临时文件
    cd - || return 1
    rm -rf "$BACKUP_DIR" "$CLEANUP_DIR"
    echo "已成功完成备份和清理"
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

# 清理临时目录
rm -rf "$TEMP_DIR"
