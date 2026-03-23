FROM node:20-alpine

RUN npm install extract-zip@2.0.1 -g
RUN npm install -g c8@10.1.2

WORKDIR /workspace
COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
