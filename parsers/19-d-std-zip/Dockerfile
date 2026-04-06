FROM debian:12-slim AS build

WORKDIR /workspace

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gdc \
        gcc \
        lcov \
        libgphobos-dev && \
    rm -rf /var/lib/apt/lists/*

COPY unzip.d /workspace/

# Build with gcov-compatible instrumentation and keep artifacts in /workspace
# so runtime can generate .gcda files next to matching .gcno files.
RUN gdc -fprofile-arcs -ftest-coverage -O0 -g \
    -o /workspace/unzip-bin /workspace/unzip.d

FROM debian:12-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libgphobos3 \
        lcov && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY --from=build /workspace/unzip-bin /workspace/unzip-bin
COPY --from=build /workspace/*.gcno /workspace/
COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
