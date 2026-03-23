FROM node:20-alpine

WORKDIR /src

RUN npm init -y
RUN npm install node-stream-zip@1.15.0
RUN npm install -g c8@10.1.2

COPY unzip.js /src/unzip.js

WORKDIR /workspace
COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
