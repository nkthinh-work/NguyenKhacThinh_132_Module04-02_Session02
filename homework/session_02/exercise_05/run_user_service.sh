#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
JAR_DIR="$(cd "$REPO_ROOT/user-service" && pwd)/build/libs"
JAR="$JAR_DIR/user-service.jar"
if [[ ! -f "$JAR" ]]; then
    echo "Missing $JAR" >&2
    echo "Build first: cd user-service && ./gradlew clean bootJar" >&2
    exit 1
fi
# Exercise 05 explicitly requests 'secret'; override if database from ex01 uses 12345678.
DB_PASSWORD="${DB_PASSWORD:-secret}"
if docker container inspect quickbite-user >/dev/null 2>&1; then
    echo 'Removing existing quickbite-user container...'
    docker rm -f quickbite-user >/dev/null
fi
docker run -d \
    --name quickbite-user \
    -p 8081:8081 \
    -v "$JAR_DIR:/app:ro" \
    -w /app \
    --add-host=host.docker.internal:host-gateway \
    -e SPRING_DATASOURCE_URL=jdbc:postgresql://host.docker.internal:5432/postgres \
    -e SPRING_DATASOURCE_USERNAME=postgres \
    -e "SPRING_DATASOURCE_PASSWORD=$DB_PASSWORD" \
    eclipse-temurin:17-jre-alpine \
    java -jar user-service.jar
printf '\n== Waiting for Spring Boot health endpoint ==\n'
if command -v curl >/dev/null 2>&1; then
    ready=0
    for attempt in 1 2 3 4 5 6 7 8 9 10; do
        if curl -fsS --max-time 3 http://localhost:8081/actuator/health | grep -q '"status":"UP"'; then
            ready=1
            break
        fi
        sleep 3
    done
    if [[ "$ready" -ne 1 ]]; then
        docker logs --tail 60 quickbite-user >&2 || true
        echo 'Spring Boot did not report UP. Verify DB password matches PostgreSQL.' >&2
        exit 1
    fi
else
    echo 'curl not found; skip automatic health verification.'
fi
printf '\n== quickbite-user logs ==\n'
docker logs --tail 60 quickbite-user
printf '\nHealth URL: http://localhost:8081/actuator/health\n'
printf 'Capture: homework/session_02/exercise_05/user_service_container.png\n'
