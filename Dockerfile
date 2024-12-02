FROM ghcr.io/nezhahq/nezha AS app

FROM nginx:stable-alpine

COPY --from=cloudflare/cloudflared:latest /usr/local/bin/cloudflared /usr/local/bin/cloudflared
COPY --from=app /etc/ssl/certs /etc/ssl/certs

COPY main.conf /etc/nginx/conf.d/main.conf 

ENV TZ=Asia/Shanghai

WORKDIR /dashboard

COPY --from=app /dashboard /dashboard

RUN chmod -R 777 /dashboard

EXPOSE 8008

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
