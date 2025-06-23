# ────────────── Base image ──────────────
FROM python:3.10-slim

# ────────────── OS packages ─────────────
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nano \
        nginx \
        apache2-utils \
        curl \
        jq \
        netcat-openbsd && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ────────────── ngrok ───────────────────
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
      | tee /etc/apt/trusted.gpg.d/ngrok.asc && \
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
      | tee /etc/apt/sources.list.d/ngrok.list && \
    apt-get update && apt-get install -y ngrok

# ────────────── Python packages ─────────
RUN pip install --no-cache-dir label-studio

# ────────────── App workspace ───────────
WORKDIR /app
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# ────────────── Container runtime ───────
EXPOSE 8080
ENTRYPOINT ["/app/entrypoint.sh"]
