FROM golang:1.22.3-alpine3.20

RUN apk add --no-cache gcc g++ musl-dev lcov git

WORKDIR /workspace

# Build go-unarr from source with cgo coverage flags enabled, so coverage
# data reflects parser internals from the bundled unarr C library.
RUN git clone --depth 1 --branch v0.2.4 https://github.com/gen2brain/go-unarr.git /workspace/src
RUN mkdir -p /workspace/.gocache
RUN cd /workspace/src && \
    GOCACHE=/workspace/.gocache \
    CGO_ENABLED=1 \
    go build -cover -coverpkg=./... -o /workspace/unarr ./cmd/unarr

COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
