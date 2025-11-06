# Nginx realip_module テスト環境

このプロジェクトは、Nginxの`ngx_http_realip_module`の動作を確認するためのテスト環境です。

## 概要

`ngx_http_realip_module`は、リバースプロキシやロードバランサーの背後にNginxがある場合に、クライアントの実際のIPアドレスを取得するためのモジュールです。このモジュールを使用すると、`X-Forwarded-For`や`X-Real-IP`などのヘッダーから実際のクライアントIPアドレスを取得できます。

## ディレクトリ構成

```
realip_module_test/
├── docker-compose.yml      # Docker Compose設定
├── nginx/
│   └── nginx.conf          # Nginx設定ファイル（realip_module設定を含む）
├── backend/
│   ├── Dockerfile          # バックエンドアプリケーション用Dockerfile
│   ├── app.py              # Flask バックエンドアプリケーション
│   └── requirements.txt    # Python依存関係
├── test.sh                 # テストスクリプト
└── README.md               # このファイル
```

## 前提条件

以下のツールがインストールされている必要があります：

- Docker
- Docker Compose
- curl
- jq（JSONの整形表示用、オプション）

## セットアップと起動

### 1. 環境の起動

```bash
cd realip_module_test
docker-compose up -d
```

### 2. サービスの確認

```bash
# コンテナの状態を確認
docker-compose ps

# Nginxのログを確認
docker logs realip_nginx

# バックエンドのログを確認
docker logs realip_backend
```

### 3. ヘルスチェック

```bash
curl http://localhost:8888/health
```

## テストの実行

### 自動テストスクリプトを実行

```bash
./test.sh
```

このスクリプトは以下のテストケースを実行します：

1. **ヘッダーなし**: 通常のリクエスト
2. **X-Forwarded-For（単一IP）**: 単一のIPアドレスを含むヘッダー
3. **X-Forwarded-For（複数IP）**: カンマ区切りで複数のIPアドレスを含むヘッダー
4. **X-Real-IP**: X-Real-IPヘッダーを使用するエンドポイント
5. **両方のヘッダー**: X-Forwarded-ForとX-Real-IPの両方を送信
6. **recursive off**: 再帰処理をオフにしたエンドポイント
7. **信頼できないIP**: プライベートIP範囲外からのヘッダー
8. **不正なヘッダー**: 無効な形式のIPアドレス

### 手動でテスト

```bash
# 基本的なリクエスト
curl http://localhost:8888/

# X-Forwarded-Forヘッダー付き
curl -H "X-Forwarded-For: 203.0.113.195" http://localhost:8888/

# X-Real-IPヘッダー付き
curl -H "X-Real-IP: 198.51.100.42" http://localhost:8888/test-xrealip

# 複数のIPアドレスを含むX-Forwarded-For
curl -H "X-Forwarded-For: 203.0.113.195, 70.41.3.18, 150.172.238.178" http://localhost:8888/
```

## Nginx realip_module の設定

### 主要な設定ディレクティブ

#### `set_real_ip_from`

信頼するプロキシのIPアドレス範囲を指定します。このディレクティブで指定されたIPアドレスからのリクエストのみ、ヘッダーからIPアドレスを取得します。

```nginx
set_real_ip_from 10.0.0.0/8;
set_real_ip_from 172.16.0.0/12;
set_real_ip_from 192.168.0.0/16;
```

#### `real_ip_header`

実際のIPアドレスを取得するヘッダーを指定します。

```nginx
real_ip_header X-Forwarded-For;  # または X-Real-IP
```

#### `real_ip_recursive`

再帰的に信頼できるIPアドレスをスキップするかどうかを設定します。

- `on`: X-Forwarded-Forに複数のIPがある場合、右から左へ順に確認し、最初の信頼できないIPを実際のIPとして使用
- `off`: ヘッダーの最後（右端）のIPを実際のIPとして使用

```nginx
real_ip_recursive on;  # または off
```

## テストエンドポイント

### `/`

デフォルトのエンドポイント。`real_ip_header X-Forwarded-For`と`real_ip_recursive on`の設定を使用します。

### `/test-xrealip`

`X-Real-IP`ヘッダーを使用するテストエンドポイント。

### `/test-no-recursive`

`real_ip_recursive off`の動作を確認するテストエンドポイント。

## レスポンス例

バックエンドアプリケーションは以下のような情報を返します：

```json
{
  "message": "Nginx realip_module test backend",
  "ip_information": {
    "request_path": "/",
    "remote_addr": "172.18.0.2",
    "headers": {
      "X-Real-IP": "203.0.113.195",
      "X-Forwarded-For": "203.0.113.195, 172.18.0.1",
      "X-Original-Remote-Addr": "203.0.113.195",
      "Host": "localhost:8888"
    }
  }
}
```

## ログの確認

Nginxのアクセスログには、realip_moduleによって取得されたIPアドレス情報が記録されます：

```bash
docker logs realip_nginx
```

ログフォーマット：

```
$remote_addr - realip=$realip_remote_addr x_forwarded_for="$http_x_forwarded_for" x_real_ip="$http_x_real_ip"
```

## トラブルシューティング

### ポート8888が既に使用されている場合

`docker-compose.yml`の`ports`セクションを変更してください：

```yaml
ports:
  - "9999:80"  # 8888から9999に変更
```

### コンテナが起動しない場合

```bash
# ログを確認
docker-compose logs

# コンテナを再ビルド
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Nginxの設定をテスト

```bash
docker exec realip_nginx nginx -t
```

## 環境の停止とクリーンアップ

```bash
# 環境の停止
docker-compose down

# コンテナ、ボリューム、ネットワークを全て削除
docker-compose down -v
```

## 参考資料

- [Nginx ngx_http_realip_module 公式ドキュメント](http://nginx.org/en/docs/http/ngx_http_realip_module.html)
- [X-Forwarded-For ヘッダーについて](https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/X-Forwarded-For)

## ライセンス

このテスト環境はMITライセンスの元で提供されます。
