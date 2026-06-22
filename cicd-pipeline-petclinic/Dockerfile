# syntax=docker/dockerfile:1

###############################################################################
# Stage 1 — Build the application with the bundled Maven wrapper (JDK 17).
# Dependency resolution is split from the source copy so the (slow) dependency
# layer is cached and only re-run when pom.xml changes.
###############################################################################
FROM eclipse-temurin:17-jdk-jammy AS build
WORKDIR /workspace

# Copy the Maven wrapper + pom first to maximise Docker layer caching.
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw && \
    ./mvnw -B -ntp dependency:go-offline

# Copy sources and build the boot jar. Tests run in CI (`./mvnw verify`),
# so the image build skips them for speed; CI gates the image on green tests.
COPY src/ src/
RUN ./mvnw -B -ntp clean package -DskipTests && \
    cp target/spring-petclinic-*.jar app.jar

###############################################################################
# Stage 2 — Minimal JRE runtime, non-root, with a container healthcheck.
###############################################################################
FROM eclipse-temurin:17-jre-jammy AS runtime
WORKDIR /app

# curl is needed for the HEALTHCHECK; install then strip apt lists.
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Run as an unprivileged user.
RUN groupadd --system spring && \
    useradd --system --gid spring --home /app spring
USER spring:spring

COPY --from=build --chown=spring:spring /workspace/app.jar app.jar

EXPOSE 8080
ENV JAVA_OPTS=""

# Spring Boot Actuator exposes /actuator/health.
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -fsS http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
