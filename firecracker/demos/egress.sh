#!/usr/bin/env bash
# 격리 데모 ③: network egress。
# ゲストから外部へ出られることを確認する。そして重要な教訓:
#   FC はゲストのトラフィックを一切フィルタしない。tap でそのまま出ていく。
#   → ゲスト→ホスト/メタデータ・エンドポイントの遮断は「オーケストレーター(iptables)の仕事」。
#     격리는 공짜가 아니다. これも請求書に載る。
set -euo pipefail
GUEST="${1:?usage: egress.sh <guest-ip>}"

echo "== 外部到達を確認 =="
curl -s --max-time 8 -X POST "http://${GUEST}:8080/run" \
  -H 'content-type: application/json' \
  -d '{"cmd":"wget -qO- http://example.com | head -3"}' || true

echo
echo "== 危険確認: ゲストはホストのメタデータ/内部にも到達しうる =="
echo "   何もしなければ通ってしまう。遮断規則を入れるのはあなた(orchestrator)。"
curl -s --max-time 8 -X POST "http://${GUEST}:8080/run" \
  -H 'content-type: application/json' \
  -d '{"cmd":"wget -qO- --timeout=3 http://169.254.169.254/ 2>&1 | head -3; echo [exit $?]"}' || true
