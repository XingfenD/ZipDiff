FROM node:20-alpine

RUN npm install extract-zip@2.0.1 -g

WORKDIR /usr/local/lib/node_modules/extract-zip
RUN sed -i 's/"yauzl":.*/"yauzl": "3.2.0"/' package.json
RUN npm install
RUN npm install -g c8@10.1.2
RUN npm install -g nyc@17.1.0

WORKDIR /workspace
COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
