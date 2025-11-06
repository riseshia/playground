#!/usr/bin/env python3
from flask import Flask, request, jsonify
import json

app = Flask(__name__)

@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def show_ip_info(path):
    """
    受け取ったリクエストのIPアドレス情報を表示
    """
    # リクエストから情報を収集
    ip_info = {
        "request_path": request.path,
        "remote_addr": request.remote_addr,  # Flaskが認識するクライアントIP
        "headers": {
            "X-Real-IP": request.headers.get('X-Real-IP'),
            "X-Forwarded-For": request.headers.get('X-Forwarded-For'),
            "X-Forwarded-Proto": request.headers.get('X-Forwarded-Proto'),
            "X-Original-Remote-Addr": request.headers.get('X-Original-Remote-Addr'),
            "Host": request.headers.get('Host'),
        },
        "all_headers": dict(request.headers)
    }

    # 見やすくフォーマット
    response = {
        "message": "Nginx realip_module test backend",
        "ip_information": ip_info
    }

    # JSON形式で返す（見やすくインデント）
    return jsonify(response), 200

@app.route('/health')
def health():
    """ヘルスチェック用エンドポイント"""
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    # 0.0.0.0 でリッスンして外部からアクセス可能にする
    app.run(host='0.0.0.0', port=8080, debug=True)
