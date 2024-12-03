FROM ghcr.io/nezhahq/nezha AS app

FROM debian:stable-slim

# 安装必要的依赖项
RUN apt-get update && apt-get install -y \
    awscli \
    tar \
    gzip \
    tzdata \
    caddy \
    cron \
    libssl-dev \  # 添加 libssl-dev
    libgrpc++ \   # 添加 libgrpc++
    protobuf-compiler \  # 添加 protobuf-compiler
    && rm -rf /var/lib/apt/lists/*

# 复制 cloudflared 二进制文件
COPY --from=cloudflare/cloudflared:latest /usr/local/bin/cloudflared /usr/local/bin/cloudflared

# 复制 SSL 证书
COPY --from=app /etc/ssl/certs /etc/ssl/certs

# 复制 Caddyfile
COPY Caddyfile /etc/caddy/Caddyfile

# 设置时区
ENV TZ=Asia/Shanghai

# 设置工作目录
WORKDIR /dashboard

# 复制应用程序
COPY --from=app /dashboard/app /dashboard/app

# 创建数据目录并设置权限
RUN mkdir -p /dashboard/data && chmod -R 777 /dashboard

# 暴露端口
EXPOSE 80

# 复制备份脚本和入口脚本
COPY backup.sh /backup.sh
COPY entrypoint.sh /entrypoint.sh

# 设置脚本可执行权限
RUN chmod +x /backup.sh && chmod +x /entrypoint.sh

# 创建 cron 目录并设置定时任务
RUN mkdir -p /var/spool/cron/crontabs && \
    echo "0 2 * * * /backup.sh >> /var/log/backup.log 2>&1" > /var/spool/cron/crontabs/root && \
    chmod 600 /var/spool/cron/crontabs/root

# 设置容器启动命令
CMD ["/entrypoint.sh"]
