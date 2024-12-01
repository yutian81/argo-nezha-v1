FROM ghcr.io/nezhahq/nezha

COPY --from=cloudflare/cloudflared:latest /usr/local/bin/cloudflared /usr/local/bin/cloudflared

ENV TZ=Asia/Shanghai

WORKDIR /dashboard

RUN mkdir -p /dashboard/data && chmod -R 777 /dashboard

EXPOSE 8008

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
