#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# 0. optional user-supplied variables
###############################################################################
ENV_FILE="${ENV_FILE:-/home/secureuser/.env}"
[[ -f "$ENV_FILE" ]] && { echo "› Loading $ENV_FILE"; source "$ENV_FILE"; }

###############################################################################
# 1. constants
###############################################################################
LABELSTUDIO_PORT=8081
PROXY_PORT=8080
BASE=/home/secureuser

CONF="$BASE/nginx.conf"
LOGS="$BASE/logs"; TMP="$BASE/tmp"
mkdir -p "$LOGS" "$TMP"/{body,proxy,fastcgi,uwsgi,scgi} \
         "$BASE/.local/share/label-studio"

###############################################################################
# 2. minimal nginx (for our use-case only)
###############################################################################
cat > "$CONF" <<NGINX
worker_processes  1;
error_log $LOGS/error.log;
pid        $BASE/nginx.pid;

events { worker_connections  1024; }

http {
    log_format origin '\$remote_addr [\$time_local] "\$request" \$status '
                      '"\$http_referer" "\$http_user_agent" "\$http_origin"';
    access_log $LOGS/access.log origin;

    client_body_temp_path $TMP/body;
    proxy_temp_path       $TMP/proxy;
    fastcgi_temp_path     $TMP/fastcgi;
    uwsgi_temp_path       $TMP/uwsgi;
    scgi_temp_path        $TMP/scgi;

    server {
        listen $PROXY_PORT;
        server_name _;

        auth_basic "Label-Studio";
        auth_basic_user_file /etc/nginx/.htpasswd;

        location / {
            proxy_pass              http://127.0.0.1:$LABELSTUDIO_PORT;
            proxy_set_header Host               \$host;
            proxy_set_header X-Real-IP          \$remote_addr;
            proxy_set_header X-Forwarded-For    \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto  https;          # <-- always https
            proxy_set_header Origin             \$http_origin;
            proxy_set_header Referer            \$http_referer;
        }
    }
}
NGINX

###############################################################################
# 3. start / discover ngrok
###############################################################################
[[ -n "${NGROK_AUTHTOKEN:-}" ]] && ngrok config add-authtoken "$NGROK_AUTHTOKEN"
ngrok http $PROXY_PORT > "$LOGS/ngrok.log" 2>&1 &
echo "• waiting for ngrok…"
for _ in {1..15}; do
  NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels \
              | jq -r '.tunnels[]?|select(.proto=="https")|.public_url' || true)
  [[ -n "$NGROK_URL" ]] && break
  sleep 1
done
[[ -z "$NGROK_URL" ]] && { echo "✗ ngrok tunnel not found"; exit 1; }

echo "➜ CSRF trusted host: $NGROK_URL"

###############################################################################
# 4. write + export **both** variable names
###############################################################################
cat > "$BASE/.local/share/label-studio/.env" <<EOF
# auto-generated
CSRF_TRUSTED_ORIGINS=$NGROK_URL
DJANGO_CSRF_TRUSTED_ORIGINS=$NGROK_URL
LABEL_STUDIO_ALLOW_ORIGIN=$NGROK_URL
LABEL_STUDIO_DISABLE_LOCAL_FILES_SECURITY=True
EOF

export CSRF_TRUSTED_ORIGINS=$NGROK_URL
export DJANGO_CSRF_TRUSTED_ORIGINS=$NGROK_URL
export LABEL_STUDIO_ALLOW_ORIGIN=$NGROK_URL
echo "• env exported to current shell"

###############################################################################
# 5. start Label-Studio
###############################################################################
label-studio start --host 0.0.0.0 --port $LABELSTUDIO_PORT &
for _ in {1..20}; do nc -z 127.0.0.1 $LABELSTUDIO_PORT && break; sleep 1; done
echo "➜ Label-Studio ready on :$LABELSTUDIO_PORT"

###############################################################################
# 6. launch nginx in foreground
###############################################################################
echo "➜ nginx ready on :$PROXY_PORT"
exec nginx -c "$CONF" -g 'daemon off;'
