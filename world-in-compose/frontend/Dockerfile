FROM ruby:3.1

WORKDIR /app

COPY app.rb /app
RUN gem install sinatra puma
EXPOSE 4567

CMD ["ruby", "app.rb"]
