FROM haskell:9-slim

WORKDIR /workspace

# Build with HPC instrumentation so coverage reflects package internals.
RUN cabal update && \
    cabal install zip-archive-0.4.3.2 -f executable --ghc-options="-O0 -fhpc"

COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
