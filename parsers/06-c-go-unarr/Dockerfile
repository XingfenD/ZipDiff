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
    CGO_CFLAGS="-O0 -g --coverage" \
    CGO_CXXFLAGS="-O0 -g --coverage" \
    CGO_LDFLAGS="--coverage" \
    sh -c 'build_log=$(go build -work -x -o /workspace/unarr ./cmd/unarr 2>&1) && \
    printf "%s\n" "$build_log" > /workspace/build.log && \
    printf "%s\n" "$build_log" | sed -n "s/^WORK=//p" | head -n 1 > /workspace/go-workdir.txt'

COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
