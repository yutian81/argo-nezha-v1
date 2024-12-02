FROM ghcr.io/nezhahq/nezha

# 安装基础工具和依赖
RUN wget -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
    && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r0/glibc-2.35-r0.apk \
    && apk add --no-cache /glibc-2.35-r0.apk \
    && rm -f /glibc-2.35-r0.apk \
    && apk add --no-cache \
        libstdc++ \
        ca-certificates \
        pcre \
        zlib \
        openssl

# 复制所需文件
COPY --from=cloudflare/cloudflared:latest /usr/local/bin/cloudflared /usr/local/bin/cloudflared
COPY --from=nginx:alpine /usr/sbin/nginx /usr/sbin/nginx
COPY --from=nginx:alpine /etc/nginx /etc/nginx
COPY --from=nginx:alpine /usr/share/nginx/html /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

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
