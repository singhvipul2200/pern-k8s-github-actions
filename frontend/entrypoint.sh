#!/bin/sh
set -e

CONFIG_PATH=/usr/share/nginx/html/config.js

cat <<EOF > "$CONFIG_PATH"
window.__ENV__ = {
  VITE_API_URL: "${VITE_API_URL}"
};
EOF

exec "$@"
