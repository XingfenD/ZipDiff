# Copyright (c) [Fendy/WHU] [2025-2026]
# Licensed under the MIT License (the "MIT License");
# You may obtain a copy of the MIT License at:
#   https://opensource.org/licenses/MIT

FROM alpine:3.20 AS env
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && apk add --no-cache gcc make musl-dev lcov gzip
RUN apk add --no-cache g++ cmake zlib-dev python3
WORKDIR /workspace

FROM env AS file_prepare
COPY src.tar.gz /workspace
RUN tar -xzf src.tar.gz && rm src.tar.gz
COPY unzip unzip-all.sh coverage.sh app.env /workspace/

FROM file_prepare AS build
RUN cd /workspace/src && \
    mkdir build-coverage && \
    cd build-coverage && \
    cmake -DCMAKE_BUILD_TYPE=Debug -DCOVERAGE=ON -DBUILD_TESTS=ON .. && \
    make -j$(nproc) unzzip

ENTRYPOINT ["./unzip-all.sh"]
