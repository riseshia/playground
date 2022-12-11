FROM ruby:3.1

WORKDIR /app

COPY fallback.rb /app
RUN gem install sinatra puma
EXPOSE 4567

CMD ["ruby", "fallback.rb"]
