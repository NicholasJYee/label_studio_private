FROM python:3.10-slim

# ── system deps ────────────────────────────────────────────────────────────
RUN apt-get update && \
    apt-get install -y nginx apache2-utils curl jq netcat-openbsd && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ── ngrok (official repo) ──────────────────────────────────────────────────
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
      | tee /etc/apt/trusted.gpg.d/ngrok.asc && \
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
      | tee /etc/apt/sources.list.d/ngrok.list && \
    apt-get update && apt-get install -y ngrok

# ── Label Studio ───────────────────────────────────────────────────────────
RUN pip install --no-cache-dir label-studio

# ── secure user, htpasswd and entrypoint ───────────────────────────────────
RUN useradd -m secureuser
COPY entrypoint.sh /home/secureuser/entrypoint.sh
RUN chmod +x /home/secureuser/entrypoint.sh && \
    htpasswd -bc /etc/nginx/.htpasswd admin idontknowthepasswordtotheadminaccount

USER secureuser
WORKDIR /home/secureuser
EXPOSE 8080
ENTRYPOINT ["/home/secureuser/entrypoint.sh"]
