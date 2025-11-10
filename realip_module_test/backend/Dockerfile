FROM ruby:3.4

WORKDIR /app

# 依存関係をインストール
COPY Gemfile .
RUN bundle install

# アプリケーションをコピー
COPY app.rb .

# 実行権限を付与
RUN chmod +x app.rb

# ポート8080を公開
EXPOSE 8080

# アプリケーションを起動
CMD ["bundle", "exec", "ruby", "app.rb"]
