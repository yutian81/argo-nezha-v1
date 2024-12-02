FROM ghcr.io/nezhahq/nezha

# 创建一个临时阶段来收集所需的库
FROM nginx:alpine AS nginx-deps
RUN mkdir -p /nginx-libs
RUN ldd /usr/sbin/nginx | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp '{}' /nginx-libs/

# 返回到主镜像
FROM ghcr.io/nezhahq/nezha

# 复制 nginx 及其依赖
COPY --from=nginx:alpine /usr/sbin/nginx /usr/sbin/nginx
COPY --from=nginx:alpine /etc/nginx /etc/nginx
COPY --from=nginx:alpine /usr/share/nginx/html /usr/share/nginx/html
COPY --from=nginx-deps /nginx-libs/* /lib/

# 复制 cloudflared
COPY --from=cloudflare/cloudflared:latest /usr/local/bin/cloudflared /usr/local/bin/cloudflared

# 配置 nginx
COPY nginx.conf /etc/nginx/conf.d/nginx.conf

# 创建必要的目录和文件
RUN mkdir -p /var/log/nginx \
    && mkdir -p /var/cache/nginx \
    && mkdir -p /run/nginx \
    && mkdir -p /var/lib/nginx \
    && mkdir -p /var/lib/nginx/tmp \
    && touch /var/log/nginx/access.log \
    && touch /var/log/nginx/error.log

ENV TZ=Asia/Shanghai
WORKDIR /dashboard
RUN mkdir -p /dashboard/data && chmod -R 777 /dashboard
EXPOSE 8008
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]
