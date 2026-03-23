FROM haskell:9-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends libbz2-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Build with HPC instrumentation so coverage reflects package internals.
RUN cabal update && \
    cabal install zip-2.1.0 --ghc-options="-O0 -fhpc"

COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
