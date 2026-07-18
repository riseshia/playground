#!/usr/bin/env bash
# 격리 데모 ②: rm -rf /。
# ゲスト内で破壊しても、消えるのはそのセッションの rootfs 사본だけ。
# ホストの base rootfs も他セッションも無傷 = per-session コピーの意味を体感。
set -euo pipefail
GUEST="${1:?usage: rmrf.sh <guest-ip>}"

echo "セッション ${GUEST} 内で rm -rf / を実行..."
curl -s --max-time 5 -X POST "http://${GUEST}:8080/run" \
  -H 'content-type: application/json' \
  -d '{"cmd":"rm -rf / --no-preserve-root 2>/dev/null; echo destroyed; ls / | head"}' || true

echo
echo "確認: ホストの base rootfs は無傷 →  ls -l \${MVM_STATE_DIR:-/srv/mvm}/rootfs.ext4"
echo "      他セッションも無事      →  curl http://<other-guest>:8080/health"
