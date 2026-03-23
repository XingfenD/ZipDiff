FROM gradle:8.10-jdk21-alpine AS build

COPY unzip /unzip
WORKDIR /unzip
RUN gradle build --no-daemon

RUN mkdir -p /tools && \
    wget -q -O /tools/jacocoagent.jar https://repo1.maven.org/maven2/org/jacoco/org.jacoco.agent/0.8.12/org.jacoco.agent-0.8.12-runtime.jar && \
    wget -q -O /tools/jacococli.jar https://repo1.maven.org/maven2/org/jacoco/org.jacoco.cli/0.8.12/org.jacoco.cli-0.8.12-nodeps.jar

FROM eclipse-temurin:21.0.5_11-jre-alpine

WORKDIR /workspace

COPY --from=build /unzip/build/libs/unzip.jar /workspace/unzip.jar
COPY --from=build /tools /tools
COPY unzip-wrapper unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
