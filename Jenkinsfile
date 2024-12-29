pipeline {
    agent any
    
    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-hub-credentials')
        DOCKER_IMAGE_FRONTEND = 'kuruvikuru/simplesite:frontend-latest'
        DOCKER_IMAGE_BACKEND = 'kuruvikuru/simplesite:backend-latest'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Frontend') {
            steps {
                dir('.') {
                    sh 'docker build -t ${DOCKER_IMAGE_FRONTEND} .'
                }
            }
        }
        
        stage('Build Backend') {
            steps {
                dir('backend') {
                    sh 'docker build -t ${DOCKER_IMAGE_BACKEND} .'
                }
            }
        }
        
        stage('Login to DockerHub') {
            steps {
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
            }
        }
        
        stage('Push Images') {
            steps {
                sh '''
                    docker push ${DOCKER_IMAGE_FRONTEND}
                    docker push ${DOCKER_IMAGE_BACKEND}
                '''
            }
        }
        
        stage('Deploy') {
            steps {
                sh '''
                    docker-compose pull
                    docker-compose up -d
                '''
            }
        }
    }
    
    post {
        always {
            sh 'docker logout'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
