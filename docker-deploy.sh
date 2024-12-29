#!/bin/bash

# Update system and install dependencies
sudo dnf update -y
sudo dnf install -y --allowerasing git docker curl

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create app directory
APP_DIR="/opt/simpleSite1"
sudo mkdir -p $APP_DIR
sudo chown $(whoami):$(whoami) $APP_DIR
cd $APP_DIR

# Clone repository
git clone -b dev2 https://github.com/pxhk/simpleSite1.git .

# Build and start containers
docker-compose up -d --build

echo "Deployment complete! Application should be running at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
