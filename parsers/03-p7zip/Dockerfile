FROM debian:12-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        build-essential \
        lcov && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Build p7zip from source with gcov instrumentation so coverage reflects
# parser internals rather than only wrapper scripts.
RUN for i in 1 2 3 4 5; do \
        git clone --depth 1 --branch v17.06 https://github.com/p7zip-project/p7zip.git src && break; \
        echo "git clone failed (attempt $i), retrying..." >&2; \
        rm -rf src; \
        sleep 3; \
    done && \
    test -d src && \
    cd /workspace/src && \
    (make clean || true) && \
    mkdir -p /workspace/src/bin && \
    cd /workspace/src/CPP/7zip/Bundles/Alone && \
    make

COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
