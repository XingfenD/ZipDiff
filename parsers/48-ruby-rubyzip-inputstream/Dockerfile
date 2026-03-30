FROM ruby:3.3-alpine

RUN gem install rubyzip -v 2.3.2
RUN gem install simplecov -v 0.22.0

WORKDIR /workspace

COPY unzip.rb /workspace/
COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT [ "/workspace/unzip-all.sh" ]
