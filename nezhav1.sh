#!/bin/bash

set -e  # 遇到错误自动退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # 重置颜色

# 带颜色的输出函数
info() { echo -e "${BLUE}[信息]${NC} $1"; }
success() { echo -e "${GREEN}[成功]${NC} $1"; }
warning() { echo -e "${YELLOW}[警告]${NC} $1"; }
error() { echo -e "${RED}[错误]${NC} $1"; }

# 检测并安装必要的编辑器
install_editor() {
    if ! command -v nano &>/dev/null; then
        warning "检测到系统未安装 nano 编辑器，正在尝试安装..."
        if command -v apt-get &>/dev/null; then
            info "检测到 apt 包管理器，尝试安装 nano..."
            sudo apt-get update && sudo apt-get install -y nano
        elif command -v yum &>/dev/null; then
            info "检测到 yum 包管理器，尝试安装 nano..."
            sudo yum install -y nano
        elif command -v apk &>/dev/null; then
            info "检测到 apk 包管理器(Alpine系统), 尝试安装 nano..."
            apk add nano vim busybox-extras
        else
            warning "无法自动安装 nano, 将尝试使用 vi/vim 编辑器"
        fi
    else
        success "nano 编辑器已安装，跳过安装步骤"
    fi
}

# 克隆仓库（使用镜像加速）
info "正在克隆仓库..."
git clone -b github https://ghproxy.net/https://github.com/yutian81/argo-nezha-v1.git || {
    error "克隆仓库失败！请检查网络连接或镜像地址"
    exit 1
}
cd argo-nezha-v1 || {
    error "进入项目目录失败"
    exit 1
}

# 生成 env.txt 配置文件
info "正在生成 env.txt 环境变量文件..."
cat > env.txt << 'EOF'
GITHUB_TOKEN=<填写你的github个人token>
GITHUB_REPO_OWNER=<填写你的github用户名>
GITHUB_REPO_NAME=<填写你用来备份的私有github仓库名>
BACKUP_BRANCH=nezha-v1
ARGO_AUTH=<填写你的argo token或json, 如果是json需要用英文单引号包裹>
ARGO_DOMAIN=<填写你的面板域名>
EOF

# 提示用户编辑配置
warning "\n请先编辑 env.txt 文件，填写正确的配置后再继续！"
install_editor  # 确保有可用的编辑器

# 自动选择可用编辑器
EDITOR=""
for editor in nano vi vim; do
    if command -v $editor &>/dev/null; then
        EDITOR=$editor
        break
    fi
done

if [ -z "$EDITOR" ]; then
    error "未找到任何文本编辑器！"
    info "请手动安装编辑器后再运行脚本："
    echo -e "  ${BLUE}Debian/Ubuntu:${NC} sudo apt-get install nano"
    echo -e "  ${BLUE}CentOS/RHEL:${NC}   sudo yum install nano"
    echo -e "  ${BLUE}Alpine:${NC}        apk add nano"
    exit 1
fi

info "将使用 ${GREEN}${EDITOR}${NC} 编辑器打开文件..."
echo -e "${YELLOW}编辑完成后：${NC}"
echo -e "  - ${BLUE}nano:${NC} 按 ${GREEN}Ctrl+X${NC}，然后输入 ${GREEN}Y${NC} 保存"
echo -e "  - ${BLUE}vi/vim:${NC} 按 ${GREEN}ESC${NC} 输入 ${GREEN}:wq${NC} 保存"
read -p "$(echo -e "${BLUE}按 Enter 键开始编辑...${NC}")" -r
$EDITOR env.txt

# 拉取镜像并启动容器
info "正在拉取 Docker 镜像..."
docker-compose pull || {
    error "拉取镜像失败！请检查 Docker 服务是否运行"
    exit 1
}

info "正在启动容器..."
docker-compose --env-file=env.txt up -d || {
    error "启动容器失败！"
    exit 1
}

success "\n部署完成！"
echo -e "${BLUE}后续操作命令：${NC}"
echo -e " - 检查容器状态: ${GREEN}docker ps -a${NC}"
echo -e " - 查看备份日志: ${GREEN}docker exec -it argo-nezha-v1 cat /dashboard/backup.log${NC}"
echo -e " - 修改配置后重新部署: ${GREEN}docker-compose --env-file=env.txt up -d${NC}"
echo -e " - 停止服务: ${GREEN}docker-compose down${NC}"
echo -e " - 重启服务: ${GREEN}docker-compose restart${NC}"
