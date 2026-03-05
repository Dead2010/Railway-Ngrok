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
    && apt clean

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

# Create startup script
RUN echo '#!/bin/bash' > /start.sh \
    && echo 'echo "=========================================="' >> /start.sh \
    && echo 'echo "Starting ngrok tunnel to SSH port 22..."' >> /start.sh \
    && echo 'echo "Using token: 3AGZkWMXr7YsLclerO066IEYFLt_4KXrzELfETgqD3yED9qku"' >> /start.sh \
    && echo 'echo "=========================================="' >> /start.sh \
    && echo '/ngrok tcp --authtoken 3AGZkWMXr7YsLclerO066IEYFLt_4KXrzELfETgqD3yED9qku --region ${REGION} 22 &' >> /start.sh \
    && echo 'sleep 5' >> /start.sh \
    && echo 'echo ""' >> /start.sh \
    && echo 'echo "Getting your SSH connection info..."' >> /start.sh \
    && echo 'echo ""' >> /start.sh \
    && echo 'curl -s http://localhost:4040/api/tunnels | python3 -c "' >> /start.sh \
    && echo 'import sys, json' >> /start.sh \
    && echo 'try:' >> /start.sh \
    && echo '    data = json.load(sys.stdin)' >> /start.sh \
    && echo '    tunnels = data.get(\"tunnels\", [])' >> /start.sh \
    && echo '    if tunnels:' >> /start.sh \
    && echo '        public_url = tunnels[0][\"public_url\"]' >> /start.sh \
    && echo '        # Remove tcp:// from the URL' >> /start.sh \
    && echo '        host_port = public_url.replace(\"tcp://\", \"\")' >> /start.sh \
    && echo '        # Split into host and port' >> /start.sh \
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
    && echo '    else:' >> /start.sh \
    && echo '        print(\"\\n❌ No tunnels found. Check if ngrok is running...\")' >> /start.sh \
    && echo 'except Exception as e:' >> /start.sh \
    && echo '        print(f\"\\n❌ Error: Could not get tunnel info. Error: {e}\")' >> /start.sh \
    && echo '        print(\"   Check if your ngrok token is valid\")' >> /start.sh \
    && echo '"' >> /start.sh \
    && echo 'echo ""' >> /start.sh \
    && echo 'echo "Starting SSH server..."' >> /start.sh \
    && echo '/usr/sbin/sshd -D' >> /start.sh \
    && chmod +x /start.sh

# Expose ports
EXPOSE 22 80 443 8080 4040 3306 8888

# Start the service
CMD ["/start.sh"]
