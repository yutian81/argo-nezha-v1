FROM ghcr.io/nezhahq/nezha

COPY --from=cloudflare/cloudflared:latest /usr/local/bin/cloudflared /usr/local/bin/cloudflared
COPY --from=nginx:alpine /etc/nginx /etc/nginx
COPY --from=nginx:alpine /usr/sbin/nginx /usr/local/bin/nginx

COPY nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/log/nginx && \
    mkdir -p /var/cache/nginx && \
    mkdir -p /var/run && \
    chmod -R 777 /var/log/nginx && \
    chmod -R 777 /var/cache/nginx && \
    chmod -R 777 /var/run

ENV TZ=Asia/Shanghai

WORKDIR /dashboard

RUN mkdir -p /dashboard/data && chmod -R 777 /dashboard

EXPOSE 8008

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
