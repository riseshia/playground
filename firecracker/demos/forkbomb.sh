#!/usr/bin/env bash
# 격리 데모 ①: fork bomb。
# セッション A に投下 → A だけ死んで、ホストと他セッションは無事、を観察する。
#
# 比較群: 同じイメージを `docker run`(pids-limit なし)で走らせて同じことをすると
#         ホストが揺れる。microVM は vCPU/mem が VM 境界で閉じているので漏れない。
set -euo pipefail
GUEST="${1:?usage: forkbomb.sh <guest-ip>   例: forkbomb.sh 172.16.1.2}"

echo "セッション ${GUEST} に fork bomb 投下..."
# レスポンスは返らない(VM 内が飽和する)ので background + timeout。
curl -s --max-time 3 -X POST "http://${GUEST}:8080/run" \
  -H 'content-type: application/json' \
  -d '{"cmd":":(){ :|:& };:"}' >/dev/null 2>&1 &

echo "投下完了。別ターミナルで確認せよ:"
echo "  - ホスト:      top / uptime      → 影響なし"
echo "  - 他セッション: curl http://172.16.2.2:8080/health → 生存"
echo "  - 当該 VM:     応答なし。mvm destroy <id> で回収。"
