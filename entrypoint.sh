#!/bin/sh
cloudflared tunnel --no-autoupdate run --token $CF_TOKEN & \
nginx & \
exec /dashboard/app
