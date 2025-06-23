#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# 0. Load secrets from /home/secureuser/.env (read-only mount expected)
###############################################################################
BASE=/home/secureuser
ENV_FILE="$BASE/.env"
if [[ -f "$ENV_FILE" ]]; then
  set -o allexport
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +o allexport
fi

: "${LS_ADMIN_EMAIL:?LS_ADMIN_EMAIL not set}"
: "${LS_ADMIN_PASSWORD:?LS_ADMIN_PASSWORD not set}"
: "${ADMIN_PASSWORD:?ADMIN_PASSWORD not set}"

###############################################################################
# 1. Constants
###############################################################################
LABELSTUDIO_PORT=8081
PROXY_PORT=8080
CONF="$BASE/nginx.conf"
LOGS="$BASE/logs"
TMP="$BASE/tmp"

mkdir -p "$LOGS" "$TMP"/{body,proxy,fastcgi,uwsgi,scgi} \
         "$BASE/.local/share/label-studio"

###############################################################################
# 2. Basic-auth for NGINX reverse proxy
###############################################################################
htpasswd -bc "$BASE/.htpasswd" admin "$ADMIN_PASSWORD"

###############################################################################
# 3. Minimal NGINX configuration
###############################################################################
cat >"$CONF" <<NGINX
worker_processes  1;
error_log $LOGS/error.log;
pid        $BASE/nginx.pid;

events { worker_connections 1024; }

http {
    server_tokens off;
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
        auth_basic_user_file $BASE/.htpasswd;

        location / {
            add_header X-Content-Type-Options nosniff;
            add_header X-Frame-Options DENY;
            add_header X-XSS-Protection "1; mode=block";
            add_header Content-Security-Policy "
              default-src 'self' https:;
              script-src 'self' 'unsafe-inline' 'unsafe-eval' blob: https://browser.sentry-cdn.com;
              style-src 'self' 'unsafe-inline' https:;
              img-src 'self' data: blob: https:;
              connect-src 'self' ws: wss: https:;
              font-src 'self' data: https:;
              frame-src 'self';
              object-src 'none';
            ";



            proxy_pass              http://127.0.0.1:$LABELSTUDIO_PORT;
            proxy_set_header Host              \$host;
            proxy_set_header X-Real-IP         \$remote_addr;
            proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;
            proxy_set_header Origin            \$http_origin;
            proxy_set_header Referer           \$http_referer;
        }
    }
}
NGINX

###############################################################################
# 4. Start (or reuse) ngrok tunnel
###############################################################################
[[ -n "${NGROK_AUTHTOKEN:-}" ]] && ngrok config add-authtoken "$NGROK_AUTHTOKEN"
ngrok http $PROXY_PORT >"$LOGS/ngrok.log" 2>&1 &
echo "• waiting for ngrok…"
for _ in {1..15}; do
  NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels \
              | jq -r '.tunnels[]? | select(.proto=="https") | .public_url' || true)
  [[ -n "$NGROK_URL" ]] && break
  sleep 1
done
[[ -z "$NGROK_URL" ]] && { echo "✗ ngrok tunnel not found"; exit 1; }
echo "➜ CSRF trusted host: $NGROK_URL"

###############################################################################
# 5. Runtime environment (security + local-files)
###############################################################################
export LABEL_STUDIO_DISABLE_SIGNUP_WITHOUT_LINK=true
export DISABLE_SIGNUP_WITHOUT_LINK=True
export LABEL_STUDIO_LOCAL_FILES_SERVING_ENABLED=true
export LABEL_STUDIO_LOCAL_FILES_DOCUMENT_ROOT="$BASE/data"
export CSRF_TRUSTED_ORIGINS=$NGROK_URL
export DJANGO_CSRF_TRUSTED_ORIGINS=$NGROK_URL
export LABEL_STUDIO_ALLOW_ORIGIN=$NGROK_URL
echo "• environment exported"

###############################################################################
# 6. Launch Label Studio with pre-created admin account
###############################################################################
label-studio start --host 0.0.0.0 --port $LABELSTUDIO_PORT \
                   --username "$LS_ADMIN_EMAIL" \
                   --password "$LS_ADMIN_PASSWORD" \
                   --no-browser &
for _ in {1..20}; do nc -z 127.0.0.1 $LABELSTUDIO_PORT && break; sleep 1; done
echo "➜ Label-Studio ready on :$LABELSTUDIO_PORT"

###############################################################################
# 7. Foreground NGINX
###############################################################################
echo "➜ nginx ready on $NGROK_URL"
exec nginx -c "$CONF" -g 'daemon off;'
