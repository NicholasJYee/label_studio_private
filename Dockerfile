# Dockerfile

FROM python:3.10-slim

RUN apt-get update && \
    apt-get install -y \
        nano \
        nginx \
        apache2-utils \
        curl \
        jq \
        fail2ban \
        netcat-openbsd && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install ngrok
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
      | tee /etc/apt/trusted.gpg.d/ngrok.asc && \
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
      | tee /etc/apt/sources.list.d/ngrok.list && \
    apt-get update && apt-get install -y ngrok

# Install Label Studio
RUN pip install --no-cache-dir label-studio

# Add non-root user
RUN useradd -m secureuser
COPY entrypoint.sh /home/secureuser/entrypoint.sh
RUN chmod +x /home/secureuser/entrypoint.sh

# Set user and workdir
USER secureuser
WORKDIR /home/secureuser
EXPOSE 8080
ENTRYPOINT ["/home/secureuser/entrypoint.sh"]
