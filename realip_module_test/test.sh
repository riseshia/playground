#!/bin/bash

# 色付き出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:8888"

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}Test: $1${NC}"
}

# サービスが起動しているか確認
check_service() {
    print_header "サービスのヘルスチェック"
    curl -s "${BASE_URL}/health" | jq . || echo -e "${RED}サービスが起動していません${NC}"
}

# テスト1: ヘッダーなし（通常のリクエスト）
test_no_headers() {
    print_header "テスト1: ヘッダーなし（通常のリクエスト）"
    print_test "X-Forwarded-For や X-Real-IP ヘッダーなしでリクエスト"
    curl -s "${BASE_URL}/" | jq .
}

# テスト2: X-Forwarded-For ヘッダーあり（単一IP）
test_xff_single() {
    print_header "テスト2: X-Forwarded-For ヘッダーあり（単一IP）"
    print_test "X-Forwarded-For: 203.0.113.195"
    curl -s -H "X-Forwarded-For: 203.0.113.195" "${BASE_URL}/" | jq .
}

# テスト3: X-Forwarded-For ヘッダーあり（複数IP）
test_xff_multiple() {
    print_header "テスト3: X-Forwarded-For ヘッダーあり（複数IP）"
    print_test "X-Forwarded-For: 203.0.113.195, 70.41.3.18, 150.172.238.178"
    curl -s -H "X-Forwarded-For: 203.0.113.195, 70.41.3.18, 150.172.238.178" "${BASE_URL}/" | jq .
}

# テスト4: X-Real-IP ヘッダーを使用するエンドポイント
test_xrealip() {
    print_header "テスト4: X-Real-IP ヘッダーを使用するエンドポイント"
    print_test "X-Real-IP: 198.51.100.42"
    curl -s -H "X-Real-IP: 198.51.100.42" "${BASE_URL}/test-xrealip" | jq .
}

# テスト5: X-Forwarded-For と X-Real-IP の両方を送信
test_both_headers() {
    print_header "テスト5: X-Forwarded-For と X-Real-IP の両方を送信"
    print_test "X-Forwarded-For: 203.0.113.195 と X-Real-IP: 198.51.100.42"
    curl -s -H "X-Forwarded-For: 203.0.113.195" -H "X-Real-IP: 198.51.100.42" "${BASE_URL}/" | jq .
}

# テスト6: recursive off のエンドポイント
test_no_recursive() {
    print_header "テスト6: recursive off のエンドポイント（複数IP）"
    print_test "X-Forwarded-For: 203.0.113.195, 192.168.1.1, 10.0.0.1"
    curl -s -H "X-Forwarded-For: 203.0.113.195, 192.168.1.1, 10.0.0.1" "${BASE_URL}/test-no-recursive" | jq .
}

# テスト7: 信頼できないIPアドレス範囲からのヘッダー
test_untrusted_ip() {
    print_header "テスト7: プライベートIP範囲外からの X-Forwarded-For"
    print_test "X-Forwarded-For: 8.8.8.8（信頼できるプロキシ範囲外）"
    curl -s -H "X-Forwarded-For: 8.8.8.8" "${BASE_URL}/" | jq .
}

# テスト8: 不正な形式のヘッダー
test_invalid_header() {
    print_header "テスト8: 不正な形式のヘッダー"
    print_test "X-Forwarded-For: invalid-ip-address"
    curl -s -H "X-Forwarded-For: invalid-ip-address" "${BASE_URL}/" | jq .
}

# メイン実行
main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Nginx realip_module テストスクリプト${NC}"
    echo -e "${GREEN}========================================${NC}"

    check_service
    test_no_headers
    test_xff_single
    test_xff_multiple
    test_xrealip
    test_both_headers
    test_no_recursive
    test_untrusted_ip
    test_invalid_header

    print_header "テスト完了"
    echo -e "${GREEN}すべてのテストが完了しました${NC}"
    echo -e "\n${YELLOW}Nginxのアクセスログを確認する:${NC}"
    echo -e "docker logs realip_nginx"
}

# スクリプト実行
main
