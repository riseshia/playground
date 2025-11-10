#!/usr/bin/env ruby
require 'rack'
require 'action_dispatch'
require 'json'

class RealIPTestApp
  def call(env)
    # Rack::Request を使用
    rack_request = Rack::Request.new(env)

    # ActionDispatch::Request を使用
    action_dispatch_request = ActionDispatch::Request.new(env)

    # ヘルスチェック
    if rack_request.path == '/health'
      return [
        200,
        { 'content-type' => 'application/json' },
        [JSON.pretty_generate({ status: 'healthy' })]
      ]
    end

    # リクエストから情報を収集
    ip_info = {
      request_path: rack_request.path,

      # Rack::Request#ip の値
      rack_request_ip: rack_request.ip,

      # ActionDispatch::Request#remote_ip の値
      action_dispatch_remote_ip: action_dispatch_request.remote_ip,

      # 生のREMOTE_ADDR
      remote_addr: env['REMOTE_ADDR'],

      # すべてのヘッダー
      headers: extract_http_headers(env),

      # 主要なヘッダーを個別に表示
      key_headers: {
        'X-Real-IP' => env['HTTP_X_REAL_IP'],
        'X-Forwarded-For' => env['HTTP_X_FORWARDED_FOR'],
        'X-Forwarded-Proto' => env['HTTP_X_FORWARDED_PROTO'],
        'X-Original-Remote-Addr' => env['HTTP_X_ORIGINAL_REMOTE_ADDR'],
        'Cf-Connecting-IP' => env['HTTP_CF_CONNECTING_IP'],
        'Host' => env['HTTP_HOST']
      }
    }

    # レスポンスを構築
    response = {
      message: 'Nginx realip_module test backend (Rack app)',
      ip_information: ip_info
    }

    [
      200,
      { 'content-type' => 'application/json' },
      [JSON.pretty_generate(response)]
    ]
  end

  private

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
end
