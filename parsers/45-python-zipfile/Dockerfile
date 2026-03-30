FROM python:3.13.0-alpine

RUN pip install --no-cache-dir coverage==7.8.0

WORKDIR /workspace

COPY unzip.py /workspace/
COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT [ "/workspace/unzip-all.sh" ]
