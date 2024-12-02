FROM ghcr.io/nezhahq/nezha

# 复制 caddy 2 可执行文件
COPY --from=caddy:2 /usr/bin/caddy /usr/bin/caddy

# 设置 Caddy 的工作目录，用于存储证书和状态
WORKDIR /etc/caddy
RUN mkdir -p /etc/caddy /usr/share/caddy /var/lib/caddy \
    && chmod -R 777 /etc/caddy /usr/share/caddy /var/lib/caddy

# 给 Caddy 配置文件适当的权限
COPY Caddyfile /etc/caddy/Caddyfile

# 复制 cloudflared 可执行文件
COPY --from=cloudflare/cloudflared:latest /usr/local/bin/cloudflared /usr/local/bin/cloudflared

# 设置时区和工作目录
ENV TZ=Asia/Shanghai
WORKDIR /dashboard
RUN mkdir -p /dashboard/data && chmod -R 777 /dashboard

# 暴露必要的端口
EXPOSE 80

# 复制自定义启动脚本
COPY backup.sh /backup.sh
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /backup.sh && chmod +x /entrypoint.sh

# 创建一个目录来存放 cron 任务
RUN mkdir -p /var/spool/cron/crontabs

# 创建一个包含 cron 任务的脚本文件
RUN echo "0 2 * * * /backup.sh >> /var/log/backup.log 2>&1" > /var/spool/cron/crontabs/root

# 设置默认启动命令
CMD ["/entrypoint.sh"]
