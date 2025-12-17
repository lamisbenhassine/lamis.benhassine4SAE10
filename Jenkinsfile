pipeline {
    agent any

    environment {
        // SonarQube
        SONAR_HOST_URL      = 'http://localhost:9000'
        SONAR_PROJECT_KEY   = 'TP-Projet-2025-isra50'
        SONAR_PROJECT_NAME  = 'TP Projet 2025 - Spring Boot'

        // Java (optionnel si déjà OK sur Jenkins)
        JAVA_HOME = '/usr/lib/jvm/java-17-openjdk-amd64'
        PATH = "${JAVA_HOME}/bin:${PATH}"

        // Docker
        DOCKER_IMAGE = 'lamisbenhassine/tpfoyer'
        DOCKER_TAG   = '1.0'   // tu peux aussi mettre "${BUILD_NUMBER}" si tu veux versionner par build

        // Email destination
        TO_EMAIL = 'lamisbenhassine6@gmail.com'
    }

    stages {

        stage('📥 Checkout Code') {
            steps {
                echo '📥 Récupération du code source depuis GitHub...'
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
                echo '🔧 Vérifications Java / Docker / kubectl / Sonar...'
                sh '''
                    set -e

                    echo "=== Java ==="
                    java -version

                    echo "=== Maven Wrapper ==="
                    chmod +x mvnw
                    ./mvnw -v

                    echo "=== Docker ==="
                    docker --version
                    docker info >/dev/null 2>&1 || (echo "❌ Docker daemon inaccessible (droits docker.sock)" && exit 1)

                    echo "=== kubectl ==="
                    kubectl version --client

                    echo "=== SonarQube ==="
                    curl -s --connect-timeout 5 "${SONAR_HOST_URL}/api/system/status" \
                      | grep -q "UP" && echo "✅ SonarQube accessible" || echo "⚠️ SonarQube non accessible"
                '''
            }
        }

        stage('🧹🔨 Clean & Compile Project') {
            steps {
                echo '🧹🔨 Nettoyage et compilation...'
                sh './mvnw clean compile -q'
            }
        }

        stage('🔍 SonarQube Analysis') {
            steps {
                echo '🔍 Analyse de qualité avec SonarQube...'
                script {
                    try {
                        withCredentials([string(credentialsId: 'jenkins-sonar', variable: 'SONAR_TOKEN')]) {
                            sh """
                                ./mvnw sonar:sonar \
                                  -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                                  -Dsonar.projectName="${SONAR_PROJECT_NAME}" \
                                  -Dsonar.host.url=${SONAR_HOST_URL} \
                                  -Dsonar.login=${SONAR_TOKEN} \
                                  -Dsonar.java.binaries=target/classes \
                                  -Dsonar.coverage.exclusions=**/test/** \
                                  -DskipTests
                            """
                        }
                    } catch (Exception e) {
                        echo "⚠️ Analyse SonarQube échouée : ${e.message}"
                        echo "➡️ Le pipeline continue..."
                    }
                }
            }
        }

        stage('📦 Build & Package') {
            steps {
                echo '📦 Construction du JAR...'
                sh '''
                    set -e
                    ./mvnw package -DskipTests -q

                    echo "=== JAR généré ==="
                    ls -lh target/*.jar || (echo "❌ Aucun JAR généré" && exit 1)
                '''
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }

        stage('🐳 Build Docker Image') {
            steps {
                echo '🐳 Build de l’image Docker...'
                sh '''
                    set -e
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker images | head -n 15
                '''
            }
        }

        
        stage('🔐 Docker Login') {
  steps {
    withCredentials([usernamePassword(
      credentialsId: 'dockerhub-token',
      usernameVariable: 'DOCKER_USER',
      passwordVariable: 'DOCKER_TOKEN'
    )]) {
      sh '''
        echo "$DOCKER_TOKEN" | docker login -u "$DOCKER_USER" --password-stdin
      '''
    }
  }
}

        stage('📤 Push Docker Image') {
            steps {
                echo '📤 Push vers Docker Hub...'
                sh '''
                    set -e
                    docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                '''
            }
        }
        
        stage('📤 Push Docker Image') {
            steps {
                echo '📤 Push vers Docker Hub...'
                sh '''
                    set -e
                    docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                '''
            }
        }

        stage('☸️ Deploy to Kubernetes (Minikube)') {
            steps {
                echo '☸️ Déploiement Kubernetes...'
                sh '''
                    set -e

                    echo "🔧 Vérification du contexte Kubernetes"
                    kubectl config use-context minikube

                    echo "🚀 Déploiement des manifests"
                    kubectl apply -f k8s/

                    echo "⏳ Attente du déploiement"
                    kubectl rollout status deployment/tpfoyer-deployment --timeout=120s

                    echo "📡 Services disponibles"
                    kubectl get svc
                '''
            }
        }

        stage('✅ Verify Deployment') {
            steps {
                echo '✅ Vérification du service exposé...'
                sh '''
                    echo "🌐 URL Minikube :"
                    minikube service tpfoyer-service --url || true
                '''
            }
        }
    }

    post {
        success {
            echo '🎉 PIPELINE RÉUSSI 🎉'
            emailext(
                to: "${TO_EMAIL}",
                subject: "[Jenkins] SUCCESS - ${JOB_NAME} #${BUILD_NUMBER}",
                body: """
Bonjour,

Le pipeline Jenkins a été exécuté avec succès ✅

- Job        : ${JOB_NAME}
- Build      : #${BUILD_NUMBER}
- Image      : ${DOCKER_IMAGE}:${DOCKER_TAG}
- Kubernetes : Déployé sur Minikube
- Console    : ${BUILD_URL}console

Cordialement,
Jenkins
"""
            )
        }

        failure {
            echo '❌ PIPELINE ÉCHOUÉ'
            emailext(
                to: "${TO_EMAIL}",
                subject: "[Jenkins] FAILURE - ${JOB_NAME} #${BUILD_NUMBER}",
                body: """
Bonjour,

❌ Le pipeline Jenkins a échoué.

- Job     : ${JOB_NAME}
- Build   : #${BUILD_NUMBER}
- Console : ${BUILD_URL}console

Merci de vérifier les logs.

Jenkins
"""
            )
        }

        always {
            echo "📊 Statut final : ${currentBuild.currentResult}"
        }
    }
}
