FROM ubuntu:latest

# Define arguments (these will be set in Railway)
ARG NGROK_TOKEN
ARG REGION=us

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV NGROK_TOKEN=${NGROK_TOKEN}
ENV REGION=${REGION}

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
    && echo 'echo "Starting ngrok tunnel to SSH port 22..."' >> /start.sh \
    && echo '/ngrok tcp --authtoken ${NGROK_TOKEN} --region ${REGION} 22 &' >> /start.sh \
    && echo 'sleep 3' >> /start.sh \
    && echo 'echo "Getting tunnel URL..."' >> /start.sh \
    && echo 'curl -s http://localhost:4040/api/tunnels | python3 -c "' >> /start.sh \
    && echo 'import sys, json' >> /start.sh \
    && echo 'try:' >> /start.sh \
    && echo '    tunnels = json.load(sys.stdin)[\"tunnels\"]' >> /start.sh \
    && echo '    if tunnels:' >> /start.sh \
    && echo '        public_url = tunnels[0][\"public_url\"]' >> /start.sh \
    && echo '        host_port = public_url.replace(\"tcp://\", \"\")' >> /start.sh \
    && echo '        host = host_port.split(\":\")[0]' >> /start.sh \
    && echo '        port = host_port.split(\":\")[1]' >> /start.sh \
    && echo '        print(\"\\n========== SSH CONNECTION INFO ==========\")\n' >> /start.sh \
    && echo '        print(f\"Command: ssh root@{host} -p {port}\")' >> /start.sh \
    && echo '        print(\"Password: akashi520\")\n' >> /start.sh \
    && echo '        print(\"==========================================\\n\")' >> /start.sh \
    && echo '    else:' >> /start.sh \
    && echo '        print(\"No tunnels found\")' >> /start.sh \
    && echo 'except:' >> /start.sh \
    && echo '    print(\"Error getting tunnel info. Check NGROK_TOKEN\")' >> /start.sh \
    && echo '"' >> /start.sh \
    && echo 'echo "Starting SSH server..."' >> /start.sh \
    && echo '/usr/sbin/sshd -D' >> /start.sh \
    && chmod +x /start.sh

# Expose ports
EXPOSE 22 80 443 8080 4040

# Start the service
CMD ["/start.sh"]
