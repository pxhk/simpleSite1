# Simple Site

A React application with Node.js backend, deployed using Docker.

## Project Structure
```
.
├── Dockerfile          # Frontend Dockerfile
├── backend/           # Backend Node.js application
│   └── Dockerfile    # Backend Dockerfile
├── nginx.conf         # Nginx reverse proxy configuration
├── docker-compose.yml # Docker Compose configuration
└── docker-deploy.sh   # Deployment script
```

## Deployment Instructions

1. SSH into your Amazon Linux 2023 instance
2. Clone this repository:
   ```bash
   curl -o docker-deploy.sh https://raw.githubusercontent.com/pxhk/simpleSite1/dev2/docker-deploy.sh
   chmod +x docker-deploy.sh
   sudo ./docker-deploy.sh
   ```

3. The application will be available at your instance's public IP address.

## Architecture

- **Frontend**: React application served by Nginx
- **Backend**: Node.js application
- **Proxy**: Nginx reverse proxy
  - Routes `/` to frontend
  - Routes `/api` to backend

## Development

To run locally:
```bash
# Install dependencies
npm install

# Start development server
npm start
```

## Production Build

The application is containerized using Docker:
```bash
docker-compose up -d --build
```

This will:
1. Build the frontend React application
2. Build the backend Node.js application
3. Set up Nginx reverse proxy
4. Start all services in containers
