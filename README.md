# Argo Nezha Dashboard V1

Nezha Dashboard 是一个基于 [Nezha](https://github.com/nezhahq/nezha) 的项目，提供了一个强大的监控和管理界面。本项目使用 Docker 进行部署，并集成了 Cloudflare Tunnel 来提供安全的访问，项目优势：

1. 不暴露公网 IP，安全可靠
2. 单栈转双栈，纯 IPv6 环境也能使用
3. 自动备份，启动时自动还原备份文件，方便在线上容器平台使用

## 最近更新
2025-01-01
- 修复备份的数据库可能受损的问题
- 修复无法删除7天前备份文件的问题
- 修改备份时间为每天凌晨2点

## 功能

- **监控和管理**: 提供实时的系统监控和管理功能。
- **自动备份**: 支持自动备份到 github 私有仓库。
- **安全访问**: 通过 nginx 和 Cloudflare Tunnel 提供安全的访问。
- **自定义配置**: 支持通过环境变量进行自定义配置。

## 快速开始

### 环境变量

在运行项目之前，需要设置以下环境变量：

- `GITHUB_TOKEN`: github的访问令牌。
- `GITHUB_REPO_OWNER`: github用户名。
- `GITHUB_REPO_NAME`: 备份到github的仓库名。
- `BACKUP_BRANCH`: github备份的分支，默认为 `nezhaV1-backup`。
- `ARGO_AUTH`: Cloudflare Argo Tunnel 令牌。
- `ARGO_DOMAIN`: 对外访问的域名。

### Tunnel 设置

在运行项目之前，需要
1. **CloudFlare开启GRPC流量代理**
2. **设置 Tunnel Public hostname**

  - Type: HTTPS
  - URL: localhost:443
  - Additional application settings
    - TLS
      - No TLS Verify on
      - HTTP2 connection on

### 构建和运行

1. **克隆仓库**:

   ```bash
   git clone https://github.com/yourusername/argo-nezha.git
   cd nezha-dashboard
   ```

2. **构建 Docker 镜像**:

   ```bash
   docker build -t argo-nezha .
   ```

3. **拉取镜像**
   ```bash
   docker pull yutian81/argo-nezha-v1:latest
   ```

3. **运行 Docker 容器**

   docke命令：
   
   ```bash
   docker run -d \
     -e GITHUB_TOKEN="your_github_token" \
     -e GITHUB_REPO_OWNER="your_github_username" \
     -e GITHUB_REPO_NAME="your_github_backup_reponame" \
     -e BACKUP_BRANCH="your_github_backup_branch" \
     -e ARGO_AUTH="your_ARGO_AUTH" \
     -e ARGO_DOMAIN="your_domain" \
     -p 443:443 \
     argo-nezha-v1
   ```

5. **更新镜像**
   
    进入你的项目目录下(compose.yml同级)
    
    ```bash
    docker compose pull
    docker compose up -d 
    ```

## Dashboard 配置
Agent对接地址【域名/IP:端口】

Public hostname:443

## Agent 安装
dashboard 右上角复制安装命令即可

## 备份和恢复

项目支持自动备份到 Github 私有仓库，并在启动时尝试恢复最新备份。备份脚本 `/backup.sh` 会在每天凌晨 2 点执行。

## 许可证

本项目采用 [MIT 许可证](LICENSE)。
