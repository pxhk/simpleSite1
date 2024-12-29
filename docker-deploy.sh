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
git clone -b dev3 https://github.com/pxhk/simpleSite1.git .

# Docker Hub login
echo "Please log in to Docker Hub to push images:"
while true; do
    if sudo docker login; then
        echo "Successfully logged in to Docker Hub"
        break
    else
        echo "Docker Hub login failed. Please try again."
        read -p "Press Enter to retry or Ctrl+C to exit"
    fi
done

# Check for local changes and build/pull images accordingly
echo "Checking and building Docker images..."

# Function to check if image exists in DockerHub
check_image_exists() {
    local image=$1
    local tag=$2
    curl --silent -f -lSL "https://hub.docker.com/v2/repositories/${image}/tags/${tag}" > /dev/null
}

# Handle frontend
FRONTEND_IMAGE="kuruvikuru/simplesite"
FRONTEND_TAG="frontend-latest"

if git diff --quiet HEAD -- . ':!backend'; then
    if check_image_exists "$FRONTEND_IMAGE" "$FRONTEND_TAG"; then
        echo "No changes detected for frontend, pulling existing image..."
        sudo docker pull ${FRONTEND_IMAGE}:${FRONTEND_TAG}
    else
        echo "Building frontend image..."
        sudo docker-compose build frontend
        echo "Pushing frontend image to Docker Hub..."
        sudo docker push ${FRONTEND_IMAGE}:${FRONTEND_TAG}
    fi
else
    echo "Changes detected for frontend, building new image..."
    sudo docker-compose build frontend
    echo "Pushing frontend image to Docker Hub..."
    sudo docker push ${FRONTEND_IMAGE}:${FRONTEND_TAG}
fi

# Handle backend
BACKEND_IMAGE="kuruvikuru/simplesite"
BACKEND_TAG="backend-latest"

if git diff --quiet HEAD -- backend; then
    if check_image_exists "$BACKEND_IMAGE" "$BACKEND_TAG"; then
        echo "No changes detected for backend, pulling existing image..."
        sudo docker pull ${BACKEND_IMAGE}:${BACKEND_TAG}
    else
        echo "Building backend image..."
        sudo docker-compose build backend
        echo "Pushing backend image to Docker Hub..."
        sudo docker push ${BACKEND_IMAGE}:${BACKEND_TAG}
    fi
else
    echo "Changes detected for backend, building new image..."
    sudo docker-compose build backend
    echo "Pushing backend image to Docker Hub..."
    sudo docker push ${BACKEND_IMAGE}:${BACKEND_TAG}
fi

# Start services
sudo docker-compose up -d

echo "Deployment complete! Application should be running at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
