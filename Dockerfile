FROM ubuntu:latest

# Your token is already set here
ENV NGROK_TOKEN=3AGZkWMXr7YsLclerO066IEYFLt_4KXrzELfETgqD3yED9qku
ENV REGION=us
ENV DEBIAN_FRONTEND=noninteractive

# Update and install packages
RUN apt update && apt install -y \
    ssh \
    wget \
    unzip \
    vim \
    curl \
    python3 \
    python3-pip \
    && apt clean

# Install a simple web server for health checks
RUN pip3 install flask

# Download and install ngrok
RUN wget -q https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -O /ngrok.zip \
    && unzip /ngrok.zip -d / \
    && rm /ngrok.zip \
    && chmod +x /ngrok

# Configure SSH
RUN mkdir /var/run/sshd \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config \
    && echo 'root:akashi520' | chpasswd

# Create a simple web server for health checks
RUN echo '#!/usr/bin/env python3' > /healthcheck.py \
    && echo 'from flask import Flask' >> /healthcheck.py \
    && echo 'app = Flask(__name__)' >> /healthcheck.py \
    && echo '@app.route("/")' >> /healthcheck.py \
    && echo 'def health():' >> /healthcheck.py \
    && echo '    return "OK", 200' >> /healthcheck.py \
    && echo 'if __name__ == "__main__":' >> /healthcheck.py \
    && echo '    app.run(host="0.0.0.0", port=80)' >> /healthcheck.py \
    && chmod +x /healthcheck.py

# Create main startup script
RUN echo '#!/bin/bash' > /start.sh \
    && echo 'echo "=========================================="' >> /start.sh \
    && echo 'echo "Starting health check web server on port 80..."' >> /start.sh \
    && echo 'python3 /healthcheck.py &' >> /start.sh \
    && echo 'echo "=========================================="' >> /start.sh \
    && echo 'echo "Starting ngrok tunnel to SSH port 22..."' >> /start.sh \
    && echo 'echo "Using token: 3AGZkWMXr7YsLclerO066IEYFLt_4KXrzELfETgqD3yED9qku"' >> /start.sh \
    && echo 'echo "=========================================="' >> /start.sh \
    && echo '/ngrok tcp --authtoken 3AGZkWMXr7YsLclerO066IEYFLt_4KXrzELfETgqD3yED9qku --region ${REGION} 22 &' >> /start.sh \
    && echo 'sleep 8' >> /start.sh \
    && echo 'echo ""' >> /start.sh \
    && echo 'echo "Getting your SSH connection info..."' >> /start.sh \
    && echo 'echo ""' >> /start.sh \
    && echo 'for i in {1..10}; do' >> /start.sh \
    && echo '    curl -s http://localhost:4040/api/tunnels > /tmp/ngrok.json' >> /start.sh \
    && echo '    if [ -s /tmp/ngrok.json ]; then' >> /start.sh \
    && echo '        python3 -c "' >> /start.sh \
    && echo 'import sys, json' >> /start.sh \
    && echo 'try:' >> /start.sh \
    && echo '    with open(\"/tmp/ngrok.json\", \"r\") as f:' >> /start.sh \
    && echo '        data = json.load(f)' >> /start.sh \
    && echo '    tunnels = data.get(\"tunnels\", [])' >> /start.sh \
    && echo '    if tunnels:' >> /start.sh \
    && echo '        public_url = tunnels[0][\"public_url\"]' >> /start.sh \
    && echo '        host_port = public_url.replace(\"tcp://\", \"\")' >> /start.sh \
    && echo '        parts = host_port.split(\":\")' >> /start.sh \
    && echo '        host = parts[0]' >> /start.sh \
    && echo '        port = parts[1] if len(parts) > 1 else \"22\"' >> /start.sh \
    && echo '        print(\"\\n✅ ========== YOUR VPS IS READY! ========== ✅\")' >> /start.sh \
    && echo '        print(\"│\")' >> /start.sh \
    && echo '        print(f\"│  🌐 SSH Command: ssh root@{host} -p {port}\")' >> /start.sh \
    && echo '        print(\"│  🔑 Password: akashi520\")' >> /start.sh \
    && echo '        print(\"│\")' >> /start.sh \
    && echo '        print(\"│  📝 How to connect:\")' >> /start.sh \
    && echo '        print(\"│  1. Open Terminal (Command Prompt/PowerShell)\")' >> /start.sh \
    && echo '        print(f\"│  2. Type: ssh root@{host} -p {port}\")' >> /start.sh \
    && echo '        print(\"│  3. When asked for password, type: akashi520\")' >> /start.sh \
    && echo '        print(\"│\")' >> /start.sh \
    && echo '        print(\"✅ ========================================== ✅\\n\")' >> /start.sh \
    && echo '        sys.exit(0)' >> /start.sh \
    && echo 'except Exception as e:' >> /start.sh \
    && echo '    pass' >> /start.sh \
    && echo '"' >> /start.sh \
    && echo '        if [ $? -eq 0 ]; then' >> /start.sh \
    && echo '            break' >> /start.sh \
    && echo '        fi' >> /start.sh \
    && echo '    fi' >> /start.sh \
    && echo '    sleep 2' >> /start.sh \
    && echo 'done' >> /start.sh \
    && echo 'echo "Starting SSH server..."' >> /start.sh \
    && echo '/usr/sbin/sshd -D' >> /start.sh \
    && chmod +x /start.sh

# Expose ports - IMPORTANT: Railway needs port 80 for health checks
EXPOSE 22 80 4040 8080 3306 8888

# Start the service
CMD ["/start.sh"]
