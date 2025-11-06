#!/usr/bin/env ruby
require 'sinatra'
require 'json'

# サーバー設定
set :bind, '0.0.0.0'
set :port, 8080

# ヘルスチェック用エンドポイント
get '/health' do
  content_type :json
  { status: 'healthy' }.to_json
end

# すべてのパスを処理
get '/*' do
  content_type :json

  # リクエストから情報を収集
  ip_info = {
    request_path: request.path,
    remote_addr: request.ip,  # Sinatraが認識するクライアントIP
    headers: {
      'X-Real-IP': request.env['HTTP_X_REAL_IP'],
      'X-Forwarded-For': request.env['HTTP_X_FORWARDED_FOR'],
      'X-Forwarded-Proto': request.env['HTTP_X_FORWARDED_PROTO'],
      'X-Original-Remote-Addr': request.env['HTTP_X_ORIGINAL_REMOTE_ADDR'],
      'Host': request.env['HTTP_HOST']
    },
    all_headers: extract_http_headers(request.env)
  }

  # レスポンスを構築
  response = {
    message: 'Nginx realip_module test backend',
    ip_information: ip_info
  }

  # JSON形式で返す（見やすくインデント）
  JSON.pretty_generate(response)
end

# HTTPヘッダーを抽出するヘルパーメソッド
def extract_http_headers(env)
  headers = {}
  env.each do |key, value|
    if key.start_with?('HTTP_')
      # HTTP_X_FORWARDED_FOR -> X-Forwarded-For の形式に変換
      header_name = key.sub(/^HTTP_/, '').split('_').map(&:capitalize).join('-')
      headers[header_name] = value
    end
  end
  headers
end
