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
        
        stage('☸️ Deploy to Kubernetes') {
    steps {
        withCredentials([file(credentialsId: 'kubeconfig-jenkins', variable: 'KUBECONFIG')]) {
            sh '''
              export KUBECONFIG=$KUBECONFIG
              kubectl config get-contexts
              kubectl apply -f k8s/
            '''
        }
    }
}


        stage('✅ Verify & Report') {
            steps {
                echo '✅ Rapport final...'
                sh '''
                    echo "=== RAPPORT FINAL ==="
                    echo "📦 Projet : ${SONAR_PROJECT_NAME}"
                    echo "🔑 Clé Sonar : ${SONAR_PROJECT_KEY}"
                    echo "🌐 Sonar : ${SONAR_HOST_URL}/dashboard?id=${SONAR_PROJECT_KEY}"
                    echo "🐳 Image : ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    echo "✅ Build #${BUILD_NUMBER} terminé"
                '''
            }
        }
    }

    post {
        always {
            script {
                def status = currentBuild.currentResult
                def subject = "[Jenkins] ${env.JOB_NAME} #${env.BUILD_NUMBER} - ${status}"

                def body = """
Bonjour,

Le pipeline Jenkins est terminé.

- Job       : ${env.JOB_NAME}
- Build     : #${env.BUILD_NUMBER}
- Statut    : ${status}
- Console   : ${env.BUILD_URL}console
- Artefacts : ${env.BUILD_URL}artifact/
- Sonar     : ${env.SONAR_HOST_URL}/dashboard?id=${env.SONAR_PROJECT_KEY}
- Docker    : ${env.DOCKER_IMAGE}:${env.DOCKER_TAG}
- K8s       : kubectl get pods / svc (voir console)

Cordialement,
Jenkins
"""

                emailext(
                    to: "${env.TO_EMAIL}",
                    subject: subject,
                    body: body
                )
            }

            echo '📊 PIPELINE TERMINÉ'
            echo "⏱️ Durée : ${currentBuild.durationString}"
            echo "📈 Statut : ${currentBuild.currentResult}"
        }

        success {
            echo '🎉 PIPELINE RÉUSSI 🎉'
        }

        failure {
            echo '❌ PIPELINE ÉCHOUÉ'
        }
    }
}
