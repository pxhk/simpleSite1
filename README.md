# Simple Site

A React application with Node.js backend, deployed using Docker and automated image management.

## Project Structure
```
.
├── Dockerfile          # Frontend Dockerfile
├── backend/           # Backend Node.js application
│   └── Dockerfile    # Backend Dockerfile
├── nginx.conf         # Nginx reverse proxy configuration
├── docker-compose.yml # Docker Compose configuration
└── docker-deploy.sh   # Deployment script with Docker Hub integration
```

## Features
- React frontend
- Node.js backend
- Nginx reverse proxy
- Docker containerization
- Automated Docker image management
- Docker Hub integration

## Docker Hub Repository
Images are automatically built and pushed to Docker Hub:
- Frontend: `kuruvikuru/simplesite:frontend-latest`
- Backend: `kuruvikuru/simplesite:backend-latest`

## Deployment Instructions

1. SSH into your Amazon Linux 2023 instance
2. Run the deployment script:
   ```bash
   curl -o docker-deploy.sh https://raw.githubusercontent.com/pxhk/simpleSite1/dev3/docker-deploy.sh
   chmod +x docker-deploy.sh
   sudo ./docker-deploy.sh
   ```

The script will:
1. Install necessary dependencies
2. Clone the repository
3. Check for code changes
4. Build and push Docker images if needed
5. Pull existing images if no changes
6. Start all services

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

## Docker Image Management

The application uses automated Docker image management:
1. Images are stored in Docker Hub
2. New images are built only when code changes are detected
3. Existing images are reused when no changes are present

### Manual Docker Commands
```bash
# Build images
docker-compose build

# Push images to Docker Hub
docker push kuruvikuru/simplesite:frontend-latest
docker push kuruvikuru/simplesite:backend-latest

# Start services
docker-compose up -d
```

## CI/CD Flow
1. Make code changes
2. Push to GitHub
3. Run deployment script on server
4. Script automatically:
   - Detects changes
   - Builds new images if needed
   - Pushes to Docker Hub
   - Updates running containers
