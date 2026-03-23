FROM python:3.13.0-alpine

RUN pip install --no-cache-dir coverage==7.8.0

COPY unzip.py /

COPY unzip unzip-all.sh coverage.sh app.env /

ENTRYPOINT [ "/unzip-all.sh" ]
