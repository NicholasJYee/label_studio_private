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

# Configure Fail2Ban filter and jail
RUN mkdir -p /etc/fail2ban/filter.d /etc/fail2ban/jail.d && \
    printf '[Definition]\nfailregex = ^<HOST> -.*"(GET|POST).*(HTTP).*" 401\n' \
      > /etc/fail2ban/filter.d/nginx-auth.conf && \
    printf '[nginx-auth]\n\
enabled = true\n\
filter = nginx-auth\n\
action = iptables[name=HTTP, port=80, protocol=tcp]\n\
logpath = /home/secureuser/data/logs/*.log\n\
maxretry = 5\n\
findtime = 600\n\
bantime = 3600\n\
backend = polling\n\
logtarget = /home/secureuser/data/logs/fail2ban.log\n\
allowipv6 = auto\n' \
      > /etc/fail2ban/jail.d/nginx-auth.local && \
    printf '[sshd]\nenabled = false\n' > /etc/fail2ban/jail.d/disable-sshd.local

COPY entrypoint.sh /home/secureuser/entrypoint.sh
RUN chmod +x /home/secureuser/entrypoint.sh

# Set user and workdir
USER secureuser
WORKDIR /home/secureuser
EXPOSE 8080
ENTRYPOINT ["/home/secureuser/entrypoint.sh"]
