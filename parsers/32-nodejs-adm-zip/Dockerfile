FROM node:20-alpine

WORKDIR /src

RUN npm init -y
RUN npm install adm-zip@0.5.16
RUN npm install -g c8@10.1.2
RUN npm install -g nyc@17.1.0

COPY unzip.js /src/unzip.js

WORKDIR /workspace
COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
