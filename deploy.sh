#!/bin/bash

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        log "✅ $1 successful"
    else
        log "❌ $1 failed"
        exit 1
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Start deployment
log "Starting deployment process..."

# Ensure script is run as ec2-user
if [ "$(whoami)" != "ec2-user" ]; then
    log "❌ This script must be run as ec2-user"
    exit 1
fi

# Update system packages
log "Updating system packages..."
sudo dnf update -y
check_status "System update"

# Install Node.js and npm if not present
if ! command_exists node; then
    log "Installing Node.js..."
    sudo dnf install -y nodejs
    check_status "Node.js installation"
fi

# Install Git if not present
if ! command_exists git; then
    log "Installing Git..."
    sudo dnf install -y git
    check_status "Git installation"
fi

# Install PM2 globally if not present
if ! command_exists pm2; then
    log "Installing PM2..."
    sudo npm install -y pm2 -g
    check_status "PM2 installation"
fi

# Create app directory
log "Setting up application directory..."
mkdir -p ~/app
cd ~/app || exit 1

# Clone or pull the repository
if [ -d "simpleSite1" ]; then
    log "Updating existing repository..."
    cd simpleSite1
    git fetch origin
    git checkout dev
    git reset --hard origin/dev
else
    log "Cloning repository..."
    git clone -b dev https://github.com/pxhk/simpleSite1.git
    cd simpleSite1 || exit 1
fi
check_status "Repository setup"

# Install frontend dependencies and build
log "Installing frontend dependencies..."
npm install
check_status "Frontend dependencies installation"

log "Building frontend..."
npm run build
check_status "Frontend build"

# Install backend dependencies
log "Installing backend dependencies..."
cd backend || exit 1
npm install
check_status "Backend dependencies installation"

# Stop existing PM2 processes if any
log "Stopping existing PM2 processes..."
pm2 stop all 2>/dev/null
pm2 delete all 2>/dev/null

# Start the backend server with PM2
log "Starting backend server..."
pm2 start server.js --name "backend-server" --time
check_status "Backend server startup"

# Set correct permissions and SELinux context
log "Setting file permissions and SELinux context..."
sudo chown -R ec2-user:nginx ~/app
sudo chmod -R 755 ~/app
sudo chmod -R 775 ~/app/simpleSite1/build  # Ensure Nginx can access build directory

# If SELinux is enabled, set the correct context
if command_exists sestatus && sestatus | grep -q "SELinux status: *enabled"; then
    log "Setting SELinux context..."
    sudo semanage fcontext -a -t httpd_sys_content_t "/home/ec2-user/app/simpleSite1/build(/.*)?"
    sudo restorecon -Rv /home/ec2-user/app/simpleSite1/build
    check_status "SELinux context setup"
fi

# Install and configure Nginx
log "Installing Nginx..."
sudo dnf install -y nginx
check_status "Nginx installation"

# Create Nginx configuration
log "Configuring Nginx..."
sudo tee /etc/nginx/conf.d/app.conf << EOF
server {
    listen 80;
    server_name _;

    root /home/ec2-user/app/simpleSite1/build;
    index index.html;

    # Handle favicon.ico
    location = /favicon.ico {
        try_files \$uri /favicon.ico =404;
        access_log off;
        log_not_found off;
    }

    location / {
        try_files \$uri \$uri/ /index.html;
        add_header 'Access-Control-Allow-Origin' '*';
    }

    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
        
        # Preflight requests
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }

    # Error pages
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF
check_status "Nginx configuration"

# Remove default Nginx configuration
sudo rm -f /etc/nginx/conf.d/default.conf

# Start Nginx
log "Starting Nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx
check_status "Nginx startup"

# Configure firewall
log "Configuring firewall..."
sudo dnf install -y firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
check_status "Firewall configuration"

# Set PM2 to start on boot
log "Configuring PM2 startup..."
pm2 startup
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ec2-user --hp /home/ec2-user
pm2 save
check_status "PM2 startup configuration"

# Final status check
log "Checking service status..."
pm2 status
sudo systemctl status nginx --no-pager

# Print completion message with helpful information
log "Deployment completed successfully! 🚀"
echo "
=================================
🌐 Application is now running!
---------------------------------
Frontend: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
Backend API: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/api/system-info
---------------------------------
Useful commands:
- Check backend logs: pm2 logs backend-server
- Check Nginx logs: sudo tail -f /var/log/nginx/error.log
- Restart backend: pm2 restart backend-server
- Restart Nginx: sudo systemctl restart nginx
================================="
