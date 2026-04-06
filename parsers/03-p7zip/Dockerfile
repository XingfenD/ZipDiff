FROM debian:12-slim

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    for i in 1 2 3 4 5; do \
        apt-get update && \
        apt-get install -y --no-install-recommends --fix-missing \
            ca-certificates \
            git \
            make \
            g++ \
            gcc \
            p7zip-full \
            lcov && \
        apt-get -f install -y && \
        rm -rf /var/lib/apt/lists/* && \
        break; \
        echo "apt install failed (attempt $i), retrying..." >&2; \
        apt-get -f install -y || true; \
        sleep 5; \
    done

WORKDIR /workspace

RUN set -eux; \
    for i in 1 2 3 4 5; do \
        git clone --depth 1 --branch v17.06 https://github.com/p7zip-project/p7zip.git /workspace/src && break; \
        echo "git clone failed (attempt $i), retrying..." >&2; \
        rm -rf /workspace/src; \
        sleep 5; \
    done; \
    test -d /workspace/src; \
    cd /workspace/src; \
    sed -i 's#^OPTFLAGS=.*#OPTFLAGS=-O0 --coverage#' makefile.machine; \
    make 7za

COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
