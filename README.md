# Hello World DevOps Project

A simple React application that displays "Hello World" along with system hostname and IP address. This project is part of a complete DevOps pipeline demonstration.

## Features

- React frontend
- Express backend
- System information display (hostname & IP)
- Docker containerization
- AWS deployment with Terraform
- CI/CD with Jenkins

## Prerequisites

- Node.js (v14 or higher)
- npm
- Git

## Local Development

1. Clone the repository:
\`\`\`bash
git clone <your-repository-url>
cd simple-devops-project
\`\`\`

2. Install dependencies:
\`\`\`bash
# Install frontend dependencies
npm install

# Install backend dependencies
cd backend
npm install
\`\`\`

3. Start the development servers:
\`\`\`bash
# Start backend server (from backend directory)
node server.js

# Start frontend server (from root directory)
npm start
\`\`\`

4. Open [http://localhost:3000](http://localhost:3000) to view the application

## Project Structure

- `/src` - React frontend code
- `/backend` - Express backend code
- `/public` - Static files
- `/terraform` - Infrastructure as Code files
- `Dockerfile` - Docker configuration
- `Jenkinsfile` - CI/CD pipeline configuration

## Available Scripts

- `npm start` - Runs the frontend in development mode
- `npm test` - Launches the test runner
- `npm run build` - Builds the app for production

## Contributing

1. Fork the repository
2. Create your feature branch (\`git checkout -b feature/AmazingFeature\`)
3. Commit your changes (\`git commit -m 'Add some AmazingFeature'\`)
4. Push to the branch (\`git push origin feature/AmazingFeature\`)
5. Open a Pull Request
