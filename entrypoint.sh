#!/bin/sh
cloudflared tunnel --no-autoupdate run --token $CF_TOKEN & \
exec /dashboard/app
