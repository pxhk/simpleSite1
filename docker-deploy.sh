#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to log messages
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
    exit 1
}

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        log "✅ $1 successful"
    else
        error "❌ $1 failed"
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running on Amazon Linux 2023
if ! grep -q "Amazon Linux 2023" /etc/os-release; then
    error "This script requires Amazon Linux 2023"
fi

# Check if script is run as root or with sudo
if [ "$EUID" -ne 0 ] && ! sudo -v >/dev/null 2>&1; then
    error "Please run this script with sudo privileges"
fi

# Update system first
log "Updating system packages..."
sudo dnf update -y
check_status "System update"

# Install git first if not present
if ! command_exists git; then
    log "Installing git..."
    sudo dnf install -y git
    check_status "Git installation"
fi

# Handle curl package separately
log "Configuring curl..."
if ! command_exists curl; then
    # Remove any conflicting curl packages
    sudo dnf remove -y curl curl-minimal >/dev/null 2>&1 || true
    # Install curl with --allowerasing to handle conflicts
    sudo dnf install -y --allowerasing curl
    check_status "Curl installation"
fi

# Install other basic tools
log "Installing basic tools..."
for tool in wget tar gzip unzip which jq; do
    if ! command_exists $tool; then
        log "Installing $tool..."
        sudo dnf install -y $tool
        check_status "$tool installation"
    fi
done

# Install Docker if not present
if ! command_exists docker; then
    log "Installing Docker..."
    sudo dnf install -y docker
    check_status "Docker installation"
    
    log "Starting Docker service..."
    sudo systemctl start docker
    sudo systemctl enable docker
    check_status "Docker service setup"
    
    # Add current user to docker group
    log "Adding user to docker group..."
    sudo usermod -aG docker $USER
    check_status "User group setup"
    
    warn "You may need to log out and back in for docker group changes to take effect"
fi

# Install Docker Compose if not present
if ! command_exists docker-compose; then
    log "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    check_status "Docker Compose installation"
fi

# Install and configure firewall if not present
if ! command_exists firewall-cmd; then
    log "Installing firewall..."
    sudo dnf install -y firewalld
    sudo systemctl start firewalld
    sudo systemctl enable firewalld
    check_status "Firewall installation"
fi

# Configure firewall
log "Configuring firewall..."
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
check_status "Firewall configuration"

# Create app directory
log "Setting up application directory..."
APP_DIR="/opt/simpleSite1"
sudo mkdir -p $APP_DIR
sudo chown $(whoami):$(whoami) $APP_DIR
cd $APP_DIR
check_status "Directory setup"

# Clone or update repository
if [ -d ".git" ]; then
    log "Updating existing repository..."
    git fetch origin
    git checkout dev2
    git reset --hard origin/dev2
else
    log "Cloning repository..."
    git clone -b dev2 https://github.com/pxhk/simpleSite1.git .
fi
check_status "Repository setup"

# Verify Docker and Docker Compose are working
log "Verifying Docker installation..."
docker --version || error "Docker is not working properly"
docker-compose --version || error "Docker Compose is not working properly"

# Stop any existing containers
if [ "$(docker ps -q)" ]; then
    log "Stopping existing containers..."
    docker-compose down || true
fi

# Build and start containers
log "Building and starting containers..."
docker-compose up -d --build
check_status "Container deployment"

# Verify containers are running
log "Verifying containers..."
sleep 10  # Wait for containers to start
if [ "$(docker ps -q | wc -l)" -ne 3 ]; then
    error "Not all containers are running. Please check docker logs"
fi

# Get container health status
log "Container status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Print completion message
log "Deployment completed successfully! 🚀"
echo "
=================================
🌐 Application is now running!
---------------------------------
Frontend: http://$PUBLIC_IP
Backend API: http://$PUBLIC_IP/api/system-info
---------------------------------
Useful commands:
- View all containers: docker ps
- View container logs: docker logs <container-name>
- View all logs: docker-compose logs
- Restart containers: docker-compose restart
- Stop containers: docker-compose down
- Update and rebuild: docker-compose up -d --build
- Check container resources: docker stats

Troubleshooting:
- Check Nginx logs: docker logs nginx-proxy
- Check Backend logs: docker logs node-backend
- Check Frontend logs: docker logs react-frontend
- Check all logs: docker-compose logs --tail=100
=================================

Note: If you can't access the application:
1. Make sure ports 80 and 443 are open in your EC2 security group
2. Wait a few minutes for all services to fully start
3. Check container logs for any errors
"

# Add cron job for container health check
log "Setting up health check..."
HEALTH_CHECK_SCRIPT="/opt/simpleSite1/health-check.sh"

# Create health check script
cat > $HEALTH_CHECK_SCRIPT << 'EOF'
#!/bin/bash
if [ "$(docker ps -q | wc -l)" -ne 3 ]; then
    cd /opt/simpleSite1
    docker-compose up -d
    echo "[$(date)] Container recovery triggered" >> /opt/simpleSite1/health-check.log
fi
EOF

chmod +x $HEALTH_CHECK_SCRIPT

# Add to crontab if not already present
if ! crontab -l | grep -q "health-check.sh"; then
    (crontab -l 2>/dev/null; echo "*/5 * * * * $HEALTH_CHECK_SCRIPT") | crontab -
fi

log "Health check configured to run every 5 minutes"
