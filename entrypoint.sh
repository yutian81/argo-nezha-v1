#!/bin/sh

ls -l /usr/local/nginx && which nginx && echo "Nginx binary is located at $(which nginx)"

# 启动 cloudflared 隧道
#cloudflared tunnel --no-autoupdate run --token $CF_TOKEN &
#cf_pid=$!

# 启动 Nginx
/usr/sbin/nginx -g "daemon off;" &
nginx_pid=$!

# 启动 /dashboard/app
#exec /dashboard/app &
#app_pid=$!

# 等待所有后台进程完成
#wait $cf_pid $nginx_pid $app_pid
wait $nginx_pid
