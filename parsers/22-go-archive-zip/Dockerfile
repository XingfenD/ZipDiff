FROM golang:1.22.3-alpine3.20 AS env

WORKDIR /workspace

RUN mkdir src /cov && cd src && go mod init main && go get github.com/evilsocket/islazy/zip
ENV GOCOVERDIR=/cov
COPY unzip unzip-all.sh coverage.sh app.env /workspace/
COPY unzip.go /workspace/src/

FROM env AS build

RUN cd /workspace/src && go build -cover -coverpkg=github.com/evilsocket/islazy/zip,./... -o unzip

COPY unzip-all.sh /
ENTRYPOINT ["/unzip-all.sh"]
