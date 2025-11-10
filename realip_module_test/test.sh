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

# テスト1: Cf-Connecting-IPあり（Cloudflare経由のシミュレーション）
test_with_cf_connecting_ip() {
    print_header "テスト1: Cf-Connecting-IPあり（Cloudflare経由）"
    print_test "Cf-Connecting-IP: 203.0.113.195, X-Forwarded-For: 203.0.113.195, 172.64.0.1, 10.0.1.1"
    echo -e "${YELLOW}シミュレーション: Client(203.0.113.195) -> Cloudflare(172.64.0.1) -> ALB(10.0.1.1) -> Nginx${NC}"
    curl -s \
        -H "Cf-Connecting-IP: 203.0.113.195" \
        -H "X-Forwarded-For: 203.0.113.195, 172.64.0.1, 10.0.1.1" \
        "${BASE_URL}/" | jq .
}

# テスト2: Cf-Connecting-IPなし（XFFのみ）
test_without_cf_connecting_ip() {
    print_header "テスト2: Cf-Connecting-IPなし（XFFのみ）"
    print_test "X-Forwarded-For: 203.0.113.195, 172.64.0.1, 10.0.1.1"
    echo -e "${YELLOW}Cf-Connecting-IPヘッダーがない場合の動作確認${NC}"
    curl -s \
        -H "X-Forwarded-For: 203.0.113.195, 172.64.0.1, 10.0.1.1" \
        "${BASE_URL}/" | jq .
}

# メイン実行
main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Nginx realip_module テストスクリプト${NC}"
    echo -e "${GREEN}Cloudflare Cf-Connecting-IP テスト${NC}"
    echo -e "${GREEN}========================================${NC}"

    check_service
    test_with_cf_connecting_ip
    test_without_cf_connecting_ip

    print_header "テスト完了"
    echo -e "${GREEN}すべてのテストが完了しました${NC}"
    echo -e "\n${YELLOW}Nginxのアクセスログを確認する:${NC}"
    echo -e "docker logs realip_nginx"
}

# スクリプト実行
main
