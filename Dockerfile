# 使用 ghcr.io/nezhahq/nezha 作为基础镜像
FROM ghcr.io/nezhahq/nezha

# 从 cloudflare/cloudflared:latest 镜像中复制 cloudflared 二进制文件
COPY --from=cloudflare/cloudflared:latest /usr/local/bin/cloudflared /usr/local/bin/cloudflared

# 安装必要的工具和依赖项
RUN apk add --no-cache nginx

# 从项目中复制 nginx.conf 文件
COPY nginx.conf /etc/nginx/nginx.conf

# 设置时区
ENV TZ=Asia/Shanghai

# 设置工作目录
WORKDIR /dashboard

# 创建数据目录并设置权限
RUN mkdir -p /dashboard/data && chmod -R 777 /dashboard

# 暴露端口
EXPOSE 8008

# 复制启动脚本
COPY entrypoint.sh /entrypoint.sh

# 赋予启动脚本执行权限
RUN chmod +x /entrypoint.sh

# 设置默认命令
CMD ["/entrypoint.sh"]
