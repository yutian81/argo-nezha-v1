FROM ghcr.io/nezhahq/nezha AS app

FROM caddy:alpine

# 安装 gRPC 运行环境所需的依赖项
RUN apk add --no-cache \
    grpc \
    protobuf \
    protoc \
    grpc-cli \
    aws-cli \
    tar \
    gzip \
    tzdata

# 复制 cloudflared 和 SSL 证书
COPY --from=cloudflare/cloudflared:latest /usr/local/bin/cloudflared /usr/local/bin/cloudflared
COPY --from=app /etc/ssl/certs /etc/ssl/certs

# 复制 Caddyfile
COPY Caddyfile /etc/caddy/Caddyfile 

# 设置时区
ENV TZ=Asia/Shanghai

# 设置工作目录
WORKDIR /dashboard

# 复制应用
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

# 设置定时任务
RUN echo "0 2 * * * /backup.sh >> /var/log/backup.log 2>&1" > /var/spool/cron/crontabs/root

# 设置容器启动命令
CMD ["/entrypoint.sh"]
