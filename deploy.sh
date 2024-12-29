#!/bin/bash

# Function to log messages with timestamps and colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        log "✅ $1 successful"
    else
        error "❌ $1 failed"
        exit 1
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Start deployment
log "Starting deployment process..."

# Update system packages
log "Updating system packages..."
sudo dnf update -y
check_status "System update"

# Install required packages
log "Installing required packages..."
sudo dnf install -y nodejs git nginx policycoreutils-python-utils
check_status "Package installation"

# Install PM2 globally if not present
if ! command_exists pm2; then
    log "Installing PM2..."
    sudo npm install -y pm2 -g
    check_status "PM2 installation"
fi

# Create proper web directory
log "Setting up web directory..."
sudo mkdir -p /var/www/myapp
sudo mkdir -p /var/www/myapp/api
check_status "Web directory setup"

# Clone repository as regular user
log "Cloning repository..."
cd /tmp
if [ -d "simpleSite1" ]; then
    rm -rf simpleSite1
fi
git clone -b dev https://github.com/pxhk/simpleSite1.git
cd simpleSite1
check_status "Repository clone"

# Build frontend
log "Building frontend..."
npm install
check_status "Frontend dependencies installation"
npm run build
check_status "Frontend build"

# Deploy frontend to proper location
log "Deploying frontend..."
sudo cp -r build/* /var/www/myapp/
check_status "Frontend deployment"

# Setup backend
log "Setting up backend..."
cd backend
npm install
check_status "Backend dependencies installation"

# Create backend directory and copy files
sudo mkdir -p /var/www/myapp/api
sudo cp -r * /var/www/myapp/api/
check_status "Backend deployment"

# Set correct ownership and permissions
log "Setting file permissions..."
sudo chown -R nginx:nginx /var/www/myapp
sudo chmod -R 755 /var/www/myapp
check_status "Permission setup"

# Configure SELinux
log "Configuring SELinux..."
sudo semanage fcontext -a -t httpd_sys_content_t "/var/www/myapp(/.*)?"
sudo restorecon -Rv /var/www/myapp
sudo setsebool -P httpd_can_network_connect 1
check_status "SELinux configuration"

# Configure Nginx
log "Configuring Nginx..."
sudo tee /etc/nginx/conf.d/app.conf << 'EOF'
server {
    listen 80 default_server;
    server_name _;

    # Root directory for static files
    root /var/www/myapp;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";

    # Handle favicon.ico
    location = /favicon.ico {
        access_log off;
        log_not_found off;
        return 204;
    }

    # Handle static files and SPA routing
    location / {
        try_files $uri $uri/ /index.html =404;
        expires 1h;
        add_header Cache-Control "public, no-transform";
    }

    # Proxy API requests
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
        
        # Preflight requests
        if ($request_method = 'OPTIONS') {
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
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF
check_status "Nginx configuration"

# Remove default Nginx configuration
sudo rm -f /etc/nginx/conf.d/default.conf

# Start backend with PM2
log "Starting backend server..."
cd /var/www/myapp/api
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true
pm2 start server.js --name "backend-server" --time
check_status "Backend server startup"

# Configure PM2 startup
log "Configuring PM2 startup..."
pm2 startup
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ec2-user --hp /home/ec2-user
pm2 save
check_status "PM2 startup configuration"

# Start Nginx
log "Starting Nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx
check_status "Nginx startup"

# Configure firewall
log "Configuring firewall..."
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
check_status "Firewall configuration"

# Clean up
log "Cleaning up..."
cd /tmp
rm -rf simpleSite1
check_status "Cleanup"

# Final status check
log "Checking service status..."
pm2 status
sudo systemctl status nginx --no-pager

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
- View backend logs: pm2 logs backend-server
- View Nginx access logs: sudo tail -f /var/log/nginx/access.log
- View Nginx error logs: sudo tail -f /var/log/nginx/error.log
- Restart backend: pm2 restart backend-server
- Restart Nginx: sudo systemctl restart nginx
=================================
"
