FROM ruby:3.3-alpine

RUN gem install rubyzip -v 2.3.2
RUN gem install simplecov -v 0.22.0

COPY unzip.rb /

COPY unzip unzip-all.sh coverage.sh app.env /

ENTRYPOINT [ "/unzip-all.sh" ]
