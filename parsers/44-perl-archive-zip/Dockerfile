FROM alpine:3.20

WORKDIR /workspace
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && apk add --no-cache gcc make musl-dev lcov gzip
RUN apk add --no-cache perl-archive-zip curl perl-dev wget
RUN curl -L https://cpanmin.us -o /usr/local/bin/cpanm && chmod +x /usr/local/bin/cpanm
RUN cpanm --notest Devel::Cover

COPY unzip.pl /workspace/src/

COPY unzip unzip-all.sh /workspace/

ENTRYPOINT [ "/workspace/unzip-all.sh" ]
