FROM swift:5.10

COPY src /src
WORKDIR /src

RUN swift build -c release -Xswiftc -profile-generate -Xswiftc -profile-coverage-mapping
RUN mkdir -p /workspace && \
    cp "$(swift build -c release --show-bin-path)/unzip" /workspace/unzip-bin

WORKDIR /workspace

COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
