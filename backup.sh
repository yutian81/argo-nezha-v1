#!/bin/sh

# 设置默认值
GITHUB_TOKEN=${GITHUB_TOKEN:-""}
GITHUB_REPO_OWNER=${GITHUB_REPO_OWNER:-""}
GITHUB_REPO_NAME=${GITHUB_REPO_NAME:-""}
BACKUP_BRANCH=${BACKUP_BRANCH:-"nezha-v1"}
CLONE_URL=https://$GITHUB_TOKEN@github.com/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME.git

# 检查必要的环境变量
if [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_REPO_OWNER" ] || [ -z "$GITHUB_REPO_NAME" ]; then
    echo "警告: 未设置GitHub环境变量, 正在跳过备份/还原"
    exit 0
fi

# GitHub配置
export GIT_AUTHOR_NAME="[Auto] DB Backup"
export GIT_AUTHOR_EMAIL="backup@nezhav1.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

# 临时目录
TEMP_DIR=$(mktemp -d)

# 恢复功能 - 恢复最新备份
restore_backup() {
    echo "正在检查GitHub repo中的最新备份"
    LATEST_BACKUP_COMMIT=$(git ls-remote --heads "$CLONE_URL" "$BACKUP_BRANCH" | awk '{print $1}') 
    if git clone --depth 1 --branch "$BACKUP_BRANCH" --single-branch "$CLONE_URL" "$TEMP_DIR/backup_repo" 2>/dev/null; then
        echo "正在从备份恢复数据..."
        mkdir -p dashboard/
        # 恢复最新的数据库和配置文件
        find "$TEMP_DIR/backup_repo/dashboard" -name "sqlite.db_*" -printf "%T@ %p\n" | sort -n | tail -1 | cut -d' ' -f2- | xargs -I{} cp {} dashboard/sqlite.db 2>/dev/null
        find "$TEMP_DIR/backup_repo/dashboard" -name "config.yaml_*" -printf "%T@ %p\n" | sort -n | tail -1 | cut -d' ' -f2- | xargs -I{} cp {} dashboard/config.yaml 2>/dev/null
        # 验证恢复结果
        [ -f "dashboard/sqlite.db" ] && echo "数据库恢复成功" || echo "警告：未找到有效数据库备份"
        [ -f "dashboard/config.yaml" ] && echo "配置恢复成功" || echo "注意：未找到配置文件备份"
    else
        echo "备份分支不存在或克隆失败, 正在初始化新数据目录"
    fi
    
    # 清理临时目录
    rm -rf "$TEMP_DIR/backup_repo"
}

# 备份功能 - 创建带时间戳的新备份
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
    sqlite3 "dashboard/sqlite.db" "VACUUM INTO '$BACKUP_DIR/dashboard/sqlite.db_$TIMESTAMP'"
    if [ $? -ne 0 ]; then
        echo "错误: 备份SQLite数据库失败"
        rm -rf "$BACKUP_DIR"
        return 1
    fi
    
    if [ -f "dashboard/config.yaml" ]; then
        echo "正在备份config.yaml"
        cp "dashboard/config.yaml" "$BACKUP_DIR/dashboard/config.yaml_$TIMESTAMP" || {
            echo "警告: 备份config.yaml失败" # 不因config.yaml备份失败而终止整个备份
        }
    fi
    
    # 克隆现有备份仓库或初始化新仓库
    echo "正在准备Git备份"
    if git clone --depth 1 --branch "$BACKUP_BRANCH" --single-branch "$CLONE_URL" "$BACKUP_DIR/repo" 2>/dev/null; then
        echo "使用现有备份仓库"
        mv "$BACKUP_DIR/repo/.git" "$BACKUP_DIR/"
        rm -rf "$BACKUP_DIR/repo"
    else
        echo "初始化新备份仓库"
        git init "$BACKUP_DIR"
    fi
    
    cd "$BACKUP_DIR" || return 1
    git remote add origin "$CLONE_URL" 2>/dev/null || true
    
    # 清理7天前的旧备份文件
    echo "正在清理7天前的旧备份文件"
    find dashboard -type f -name "sqlite.db_*" -mtime +7 -exec git rm {} \; 2>/dev/null || \
    find dashboard -type f -name "sqlite.db_*" -mtime +7 -exec rm -f {} \;
    find dashboard -type f -name "config.yaml_*" -mtime +7 -exec git rm {} \; 2>/dev/null || \
    find dashboard -type f -name "config.yaml_*" -mtime +7 -exec rm -f {} \;
    
    # 添加新备份文件
    git add .
    git commit -m "nezha-v1 Backup $COMMIT_TIME"
    
    # 推送到GitHub
    echo "正在推送备份到GitHub..."
    git push origin "HEAD:$BACKUP_BRANCH" --force
    if [ $? -ne 0 ]; then
        echo "错误: 推送备份到GitHub失败"
        cd - || return 1
        rm -rf "$BACKUP_DIR"
        return 1
    fi
    
    # 清理临时文件
    cd - || return 1
    rm -rf "$BACKUP_DIR"
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
