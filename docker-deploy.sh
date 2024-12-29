#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Function to log messages
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
    exit 1
}

# Update system
log "Updating system packages..."
sudo dnf update -y || error "Failed to update system packages"

# Install Docker
log "Installing Docker..."
sudo dnf install -y docker || error "Failed to install Docker"
sudo systemctl start docker
sudo systemctl enable docker

# Install Docker Compose
log "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add current user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Clone repository
log "Cloning repository..."
cd /tmp
rm -rf simpleSite1 || true
git clone -b dev2 https://github.com/pxhk/simpleSite1.git
cd simpleSite1

# Build and start containers
log "Building and starting containers..."
docker-compose up -d --build

# Configure firewall
log "Configuring firewall..."
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# Print completion message
log "Deployment completed successfully! 🚀"
echo "
=================================
🌐 Application is now running!
---------------------------------
Frontend: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
Backend API: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/api/system-info
---------------------------------
Useful commands:
- View all containers: docker ps
- View container logs: docker logs <container-name>
- Restart containers: docker-compose restart
- Stop containers: docker-compose down
- Update and rebuild: docker-compose up -d --build
================================="
