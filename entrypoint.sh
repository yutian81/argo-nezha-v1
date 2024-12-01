#!/bin/sh
export PATH=$PATH:/usr/sbin
cloudflared tunnel --no-autoupdate run --token $CF_TOKEN & \
nginx & \
exec /dashboard/app
