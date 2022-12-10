FROM ruby:3.1

WORKDIR /app

COPY config.ru /app
RUN gem install rack rack-reverse-proxy rackup
EXPOSE 9292

CMD ["rackup", "--host", "0.0.0.0"]
