FROM ghcr.io/nezhahq/nezha AS app

FROM caddy:alpine

# 安装基础依赖和gRPC相关包
RUN apk add --no-cache \
    aws-cli \
    tar \
    gzip \
    tzdata \
    protobuf \
    protobuf-dev \
    gcc \
    g++ \
    make \
    libc-dev

# 安装 grpc 相关依赖
RUN apk add --no-cache \
    python3 \
    py3-pip \
    && pip3 install --no-cache-dir grpcio protobuf

COPY --from=cloudflare/cloudflared:latest /usr/local/bin/cloudflared /usr/local/bin/cloudflared
COPY --from=app /etc/ssl/certs /etc/ssl/certs
COPY Cadd

ENV TZ=Asia/Shanghai

WORKDIR /dashboard
COPY --from=app /dashboard/app /dasoard/data && chmod -R 777 /dashboard

EXPOSE 8080

COPY backup.sh /backup.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /backup.sh && chmod +x /entrypoint.sh

RUN echo "0 2 * * * /backup.sh >> /var/log/backup.log 2>&1" > /var/spool/cron/crontabs/root

CMD ["/entrypoint.sh"]
