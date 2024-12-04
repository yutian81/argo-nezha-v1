# Nezha Dashboard V1 With Argo

Nezha Dashboard 是一个基于 [Nezha](https://github.com/nezhahq/nezha) 的项目，提供了一个强大的监控和管理界面。本项目使用 Docker 进行部署，并集成了 Cloudflare Tunnel 来提供安全的访问，项目优势：

1. 不暴露公网 IP，安全可靠
2. 单栈转双栈，纯 IPv6 环境也能使用
3. 自动备份，启动时自动还原备份文件，方便在线上容器平台使用

## 功能

- **监控和管理**: 提供实时的系统监控和管理功能。
- **自动备份**: 支持自动备份到 Cloudflare R2 存储。
- **安全访问**: 通过 Caddy 2 和 Cloudflare Tunnel 提供安全的访问。
- **自定义配置**: 支持通过环境变量进行自定义配置。

## 快速开始

### 环境变量

在运行项目之前，需要设置以下环境变量：

- `R2_ACCESS_KEY_ID`: Cloudflare R2 访问密钥 ID。
- `R2_SECRET_ACCESS_KEY`: Cloudflare R2 访问密钥。
- `R2_ENDPOINT_URL`: Cloudflare R2 端点 URL。
- `R2_BUCKET_NAME`: Cloudflare R2 存储桶名称。
- `CF_TOKEN`: Cloudflare Tunnel 令牌。
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

3. **运行 Docker 容器**:

   ```bash
   docker run -d \
     -e R2_ACCESS_KEY_ID="your_access_key_id" \
     -e R2_SECRET_ACCESS_KEY="your_secret_access_key" \
     -e R2_ENDPOINT_URL="your_endpoint_url" \
     -e R2_BUCKET_NAME="your_bucket_name" \
     -e CF_TOKEN="your_cf_token" \
     -e ARGO_DOMAIN="your_domain" \
     -p 443:443 \
     argo-nezha
   ```

## Dashboard 配置
Agent对接地址【域名/IP:端口】

Public hostname:443

## Agent 安装
dashboard 右上角复制安装命令即可

## 备份和恢复

项目支持自动备份到 Cloudflare R2 存储，并在启动时尝试恢复最新备份。备份脚本 `/backup.sh` 会在每天凌晨 2 点执行。

## 许可证

本项目采用 [MIT 许可证](LICENSE)。
