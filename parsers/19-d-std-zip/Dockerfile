FROM alpine:3.20 AS build

WORKDIR /workspace

RUN apk add dmd gcc musl-dev --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main

COPY unzip.d /workspace/

# `-i` asks dmd to compile imported modules from source (including std.zip),
# so runtime coverage output includes standard-library internals.
RUN dmd -i -cov -of/workspace/unzip-bin /workspace/unzip.d

FROM alpine:3.20

RUN apk add llvm-libunwind

WORKDIR /workspace

COPY --from=build /workspace/unzip-bin /workspace/unzip-bin
COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
