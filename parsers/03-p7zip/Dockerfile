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
RUN git clone --depth 1 --branch v17.06 https://github.com/p7zip-project/p7zip.git src && \
    cd /workspace/src && \
    (make clean || true) && \
    make 7za \
        CFLAGS="-O0 -g --coverage" \
        CXXFLAGS="-O0 -g --coverage" \
        LDFLAGS="--coverage" \
        CFLAGS_BASE="-O0 -g --coverage" \
        CXXFLAGS_BASE="-O0 -g --coverage" \
        LDFLAGS_BASE="--coverage"

COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
