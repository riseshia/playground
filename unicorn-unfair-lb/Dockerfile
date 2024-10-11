FROM ruby:3.3

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["bundle", "exec", "pitchfork", "-c", "pitchfork.rb", "config.ru"]
