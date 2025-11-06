FROM python:3.11-slim

WORKDIR /app

# 依存関係をインストール
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# アプリケーションをコピー
COPY app.py .

# 実行権限を付与
RUN chmod +x app.py

# ポート8080を公開
EXPOSE 8080

# アプリケーションを起動
CMD ["python", "app.py"]
