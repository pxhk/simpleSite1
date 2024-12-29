#!/bin/bash

# Update system packages
sudo dnf update -y

# Install Node.js and npm
sudo dnf install -y nodejs

# Install Git
sudo dnf install -y git

# Install PM2 globally
sudo npm install -y pm2 -g

# Create app directory
mkdir -p ~/app

# Clone the repository
cd ~/app
git clone https://github.com/pxhk/simpleSite1.git
cd simpleSite1

# Install frontend dependencies
npm install

# Build the React app
npm run build

# Install backend dependencies
cd backend
npm install

# Start the backend server with PM2
pm2 start server.js --name "backend-server"

# Install and configure Nginx
sudo dnf install -y nginx

# Create Nginx configuration
sudo tee /etc/nginx/conf.d/app.conf << EOF
server {
    listen 80;
    server_name _;

    location / {
        root /home/ec2-user/app/simpleSite1/build;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Remove default Nginx configuration
sudo rm -f /etc/nginx/conf.d/default.conf

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Configure firewall
sudo dnf install -y firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# Set PM2 to start on boot
pm2 startup
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ec2-user --hp /home/ec2-user
pm2 save

echo "Deployment completed!"
