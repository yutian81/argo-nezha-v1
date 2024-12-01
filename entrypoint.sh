#!/bin/sh
cloudflared tunnel --no-autoupdate run --token $CF_TOKEN & \
/usr/sbin/nginx & \
exec /dashboard/app
