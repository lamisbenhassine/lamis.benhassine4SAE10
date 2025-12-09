pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                echo 'Clonage du dépôt Git...'
                git branch: 'main',
                    url: 'https://github.com/lamisbenhassine/lamis.benhassine4SAE10.git'
            }
        }

        stage('Fix permissions') {
            steps {
                echo 'Correction des permissions pour mvnw...'
                sh 'chmod +x mvnw'
            }
        }

        stage('Clean') {
            steps {
                echo 'Nettoyage du projet...'
                sh './mvnw clean'
            }
        }

        stage('Compile') {
            steps {
                echo 'Compilation du projet...'
                sh './mvnw compile'
            }
        }

        stage('Test') {
            steps {
                echo 'Exécution des tests...'
                sh './mvnw test'
            }
        }

        stage('Package') {
            steps {
                echo 'Génération du fichier JAR...'
                sh './mvnw package -DskipTests'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline CI exécuté avec succès'
        }
        failure {
            echo '❌ Échec du pipeline CI'
        }
    }
}
