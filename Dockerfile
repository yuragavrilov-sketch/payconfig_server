# syntax=docker/dockerfile:1
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn -q -B -DskipTests package

FROM eclipse-temurin:21-jre
# Run as a non-root numeric UID. 1000 matches the k8s Deployment `runAsUser: 1000`
# and avoids creating a named user (the JRE base image may already use GID/UID 1000).
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /build/target/app.jar app.jar
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0"
USER 1000
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
