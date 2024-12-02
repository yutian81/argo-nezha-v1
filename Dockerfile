FROM ghcr.io/nezhahq/nezha AS app

FROM nginx:stable-alpine

RUN apk add --no-cache aws-cli tar gzip tzdata

COPY --from=cloudflare/cloudflared:latest /usr/local/bin/cloudflared /usr/local/bin/cloudflared
COPY --from=app /etc/ssl/certs /etc/ssl/certs

COPY main.conf /etc/nginx/conf.d/main.conf 

ENV TZ=Asia/Shanghai

WORKDIR /dashboard

COPY --from=app /dashboard/app /dashboard/app

RUN mkdir -p /dashboard/data && chmod -R 777 /dashboard

EXPOSE 8008

COPY backup.sh /backup.sh
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x backup.sh && chmod +x /entrypoint.sh
RUN echo "0 2 * * * /backup.sh >> /var/log/backup.log 2>&1" > /var/spool/cron/crontabs/root

CMD ["/entrypoint.sh"]
