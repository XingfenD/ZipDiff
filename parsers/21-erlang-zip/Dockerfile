FROM erlang:27.1.2.0-alpine

WORKDIR /workspace

COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
