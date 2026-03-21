# Copyright (c) [Fendy/WHU] [2025-2026]
# Licensed under the MIT License (the "MIT License");
# You may obtain a copy of the MIT License at:
#   https://opensource.org/licenses/MIT

FROM debian:12-slim AS apt_updated
COPY debian.sources /etc/apt/sources.list.d

RUN sed -i 's|https://|http://|g' /etc/apt/sources.list.d/debian.sources && \
    apt-get update && \
    apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i 's|http://|https://|g' /etc/apt/sources.list.d/debian.sources && \
    apt-get update

FROM apt_updated as pre_build
WORKDIR /workspace

COPY src.tar.gz /workspace
RUN tar -xzf src.tar.gz && rm src.tar.gz
RUN apt-get install -y gprbuild gnat-12 lcov make && apt-get clean && rm -rf /var/lib/apt/lists/*

FROM pre_build as build
RUN cd src && gprbuild -p -P zipada.gpr -XZip_Build_Mode=Coverage
COPY unzip unzip-all.sh coverage.sh /workspace

ENTRYPOINT ["/unzip-all.sh"]
