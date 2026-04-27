# Expects target/*.jar to exist (run `mvn package -DskipTests` first locally).
# In CI, the JAR is produced by the Maven build job and downloaded as an artifact.
FROM eclipse-temurin:8-jre-alpine
WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY target/*.jar app.jar
RUN chown appuser:appgroup app.jar

USER appuser
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
