FROM ghcr.io/nezhahq/nezha AS app

FROM nginx:stable-alpine

COPY --from=cloudflare/cloudflared:latest /usr/local/bin/cloudflared /usr/local/bin/cloudflared
COPY --from=app /etc/ssl/certs /etc/ssl/certs
COPY --from=app /dashboard /dashboard

COPY main.conf /etc/nginx/conf.d/main.conf 

ENV TZ=Asia/Shanghai

WORKDIR /dashboard

RUN chmod -R 777 /dashboard
RUN sysctl -w net.core.rmem_max=8388608
RUN sysctl -w net.core.rmem_default=8388608

EXPOSE 8008

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
