FROM ruby:3.3-alpine

WORKDIR /workspace

RUN mkdir /workspace/src

COPY unzip.rb Gemfile /workspace/src/
COPY unzip unzip-all.sh /workspace/

RUN cd /workspace/src && bundle install

ENTRYPOINT [ "/workspace/unzip-all.sh" ]
