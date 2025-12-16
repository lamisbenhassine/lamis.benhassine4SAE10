# Image Java légère
FROM eclipse-temurin:17-jre

# Dossier de travail dans le conteneur
WORKDIR /app

# Copier le JAR généré par Maven
COPY target/TP-Projet-2025-0.0.1-SNAPSHOT.jar app.jar

# Port exposé par Spring Boot
EXPOSE 8080

# Lancer l'application
ENTRYPOINT ["java","-jar","app.jar"]
