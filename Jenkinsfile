pipeline {
    agent any

    environment {
        SONAR_HOST_URL      = 'http://localhost:9000'
        SONAR_PROJECT_KEY   = 'TP-Projet-2025-isra50'
        SONAR_PROJECT_NAME  = 'TP Projet 2025 - Spring Boot'

        JAVA_HOME = '/usr/lib/jvm/java-17-openjdk-amd64'
        PATH = "${JAVA_HOME}/bin:${PATH}"

        DOCKER_IMAGE = 'lamisbenhassine/tpfoyer'
        DOCKER_TAG   = "${BUILD_NUMBER}"

        TO_EMAIL = 'lamisbenhassine6@gmail.com'
    }

    stages {

        stage('📥 Checkout Code') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/lamisbenhassine/lamis.benhassine4SAE10.git',
                        credentialsId: 'jenkins-git'
                    ]]
                ])
            }
        }

        stage('🔧 Setup Environment') {
            steps {
                sh '''
                    java -version
                    chmod +x mvnw
                    ./mvnw -v
                    docker --version
                    kubectl version --client
                '''
            }
        }

        stage('🧹 Clean & Compile') {
            steps {
                sh './mvnw clean compile -DskipTests'
            }
        }

        stage('🔍 SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'jenkins-sonar', variable: 'SONAR_TOKEN')]) {
                    sh """
                        ./mvnw sonar:sonar \
                          -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                          -Dsonar.projectName="${SONAR_PROJECT_NAME}" \
                          -Dsonar.host.url=${SONAR_HOST_URL} \
                          -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

        stage('📦 Build JAR') {
            steps {
                sh './mvnw package -DskipTests'
                archiveArtifacts artifacts: 'target/*.jar'
            }
        }

        stage('🐳 Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
            }
        }

        stage('🔐 Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-token',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_TOKEN'
                )]) {
                    sh 'echo "$DOCKER_TOKEN" | docker login -u "$DOCKER_USER" --password-stdin'
                }
            }
        }

        stage('📤 Push Docker Image') {
            steps {
                sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
            }
        }

        stage('☸️ Deploy to Kubernetes') {
  steps {
    sh """
      kubectl apply -f k8s/
      kubectl set image deployment/tpfoyer-deployment tpfoyer=${DOCKER_IMAGE}:${DOCKER_TAG}
      kubectl rollout status deployment tpfoyer-deployment
    """
  }
}


        stage('✅ Verify Deployment') {
            steps {
                sh '''
                    kubectl get pods
                    kubectl get svc
                '''
            }
        }
    }

    post {
        success {
            emailext(
                to: "${TO_EMAIL}",
                subject: "✅ Jenkins SUCCESS - ${JOB_NAME} #${BUILD_NUMBER}",
                body: """
Pipeline réussi 🎉

Docker Image : ${DOCKER_IMAGE}:${DOCKER_TAG}
Sonar : ${SONAR_HOST_URL}/dashboard?id=${SONAR_PROJECT_KEY}
Jenkins : ${BUILD_URL}
"""
            )
        }

        failure {
            echo '❌ PIPELINE ÉCHOUÉ'
        }
    }
}
