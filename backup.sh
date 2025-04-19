#!/bin/sh

# 设置默认值
GITHUB_TOKEN=${GITHUB_TOKEN:-""}
GITHUB_REPO_OWNER=${GITHUB_REPO_OWNER:-""}
GITHUB_REPO_NAME=${GITHUB_REPO_NAME:-""}
BACKUP_BRANCH=${BACKUP_BRANCH:-"nezha-v1"}
CLONE_URL=https://$GITHUB_TOKEN@github.com/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME.git

# 统一错误处理函数
die() { echo "错误: $*" >&2; exit 1; }

# 检查必要环境变量
[ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_REPO_OWNER" ] || [ -z "$GITHUB_REPO_NAME" ] && {
    die "未设置必要环境变量, 正在跳过备份/还原"
}

# 初始化环境
export GIT_AUTHOR_NAME="[Auto] DB Backup"
export GIT_AUTHOR_EMAIL="backup@nezhav1.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
export TZ=Asia/Shanghai
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# 通用恢复函数
restore_latest() {
    local file_type=$1 pattern=$2 target=$3
    local latest_file=$(find "$TEMP_DIR/backup_repo/dashboard" -name "$pattern" -printf "%T@ %p\n" 2>/dev/null | 
                      sort -n | tail -1 | cut -d' ' -f2-)
    
    [ -z "$latest_file" ] && { echo "注意: 未找到$file_type备份文件"; return; }
    
    cp "$latest_file" "$target" 2>/dev/null && \
        echo "$file_type 恢复成功 (来自: $(basename "$latest_file"))" || \
        die "$file_type 恢复失败"
}

# 恢复备份
restore_backup() {
    echo "正在检查GitHub repo中的最新备份"
    git ls-remote --heads "$CLONE_URL" "$BACKUP_BRANCH" >/dev/null 2>&1 || {
        echo "备份分支不存在，跳过恢复"
        return
    }
    
    git clone --depth 1 --branch "$BACKUP_BRANCH" --single-branch "$CLONE_URL" "$TEMP_DIR/backup_repo" 2>/dev/null || \
        die "克隆备份仓库失败"
    
    echo "正在从备份恢复数据..."
    mkdir -p dashboard/
    restore_latest "数据库" "sqlite_*.db" "dashboard/sqlite.db"
    restore_latest "配置" "config_*.yaml" "dashboard/config.yaml"
}

# 创建备份
create_backup() {
    TIMESTAMP=$(date +'%Y%m%d-%H%M%S')
    COMMIT_TIME=$(date +'%Y-%m-%d %H:%M:%S %Z')
    BACKUP_DIR="$TEMP_DIR/backup_$TIMESTAMP"
    
    [ ! -f "dashboard/sqlite.db" ] && die "数据库文件不存在"
    
    mkdir -p "$BACKUP_DIR/dashboard"
    sqlite3 "dashboard/sqlite.db" "VACUUM INTO '$BACKUP_DIR/dashboard/sqlite_$TIMESTAMP.db'" || \
        die "数据库sqlite.db备份失败"
    
    [ -f "dashboard/config.yaml" ] && {
        cp "dashboard/config.yaml" "$BACKUP_DIR/dashboard/config_$TIMESTAMP.yaml" || \
        die "配置文件config.yaml备份失败"
    }
    
    # 初始化Git仓库
    if git clone --depth 1 --branch "$BACKUP_BRANCH" --single-branch "$CLONE_URL" "$BACKUP_DIR/repo" 2>/dev/null; then
        mv "$BACKUP_DIR/repo/.git" "$BACKUP_DIR/"
        rm -rf "$BACKUP_DIR/repo"
    else
        git init "$BACKUP_DIR"
    fi
    
    (
        cd "$BACKUP_DIR" || exit 1
        git remote add origin "$CLONE_URL" 2>/dev/null
        
        # 清理旧备份
        DELETED_FILES=$(find dashboard -type f \( -name "sqlite_*.db" -o -name "config_*.yaml" \) -mtime +7 -print)
        [ -n "$DELETED_FILES" ] && {
            echo "清理过期备份:"
            echo "$DELETED_FILES" | tr '\n' '\0' | xargs -0 -r git rm --quiet --cached
            echo "$DELETED_FILES" | tr '\n' '\0' | xargs -0 -r rm -f
            git commit -m "自动清理: 删除超过7天的备份" --allow-empty
        }
        
        # 添加新备份
        git add dashboard/sqlite_$TIMESTAMP.db dashboard/config_$TIMESTAMP.yaml
        git commit -m "新增备份 $COMMIT_TIME"
        git push origin "HEAD:$BACKUP_BRANCH" || die "推送备份到GitHub失败"
    )
    
    echo "备份完成！新增备份文件："
    echo " - sqlite_$TIMESTAMP.db"
    echo " - config_$TIMESTAMP.yaml"
}

# 主逻辑
case "$1" in
    restore) restore_backup ;;
    backup)  create_backup ;;
    *)       echo "Usage: $0 {backup|restore}" >&2; exit 1 ;;
esac
