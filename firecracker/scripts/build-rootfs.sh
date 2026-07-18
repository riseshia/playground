#!/usr/bin/env bash
# Step 2: Docker イメージ → ext4 rootfs。
#
# これが「イメージは(スクリプト化すれば)簡単」を体現するスクリプト。
# 素の `docker export` だと microVM で panic する。このスクリプトが黙って直している 5 つ:
#   (1) PID1(init) がない            → Dockerfile で OpenRC を仕込み済み
#   (2) ttyS0 の getty がない         → Dockerfile で agetty.ttyS0 を登録済み
#   (3) root パスワード              → Dockerfile で passwd -d 済み(シリアルから即ログイン)
#   (4) /etc/resolv.conf がない       → ここで書き込む(docker は実行時 bind-mount するため export に入らない)
#   (5) ext4 のサイジング            → tar サイズ + メタデータ余白を確保して mkfs
set -euo pipefail

IMAGE="${1:-fc-chatbot:latest}"
OUT="${2:-${MVM_STATE_DIR:-/srv/mvm}/rootfs.ext4}"
CTX="$(cd "$(dirname "$0")/../chatbot" && pwd)"

echo "== 1. chatbot イメージをビルド =="
docker build -t "$IMAGE" "$CTX"

echo "== 2. コンテナから rootfs を export =="
cid="$(docker create "$IMAGE")"
trap 'docker rm -f "$cid" >/dev/null 2>&1 || true' EXIT
tmp="$(mktemp -d)"
docker export "$cid" | tar -x -C "$tmp"

echo "== 3. export に入らないファイルを補完 =="
echo "nameserver 8.8.8.8" > "$tmp/etc/resolv.conf"
# ゲストで MMDS(セッション情報)を引くためのルート・エントリポイント補助を local.d に置く。
mkdir -p "$tmp/etc/local.d"
cat > "$tmp/etc/local.d/mmds.start" <<'EOF'
#!/bin/sh
# MMDS(169.254.169.254)へ経路を通し、session_id を取得して chatbot に渡す。
ip route add 169.254.169.254 dev eth0 2>/dev/null || true
TOKEN=$(wget -qO- --method=PUT --header='X-metadata-token-ttl-seconds: 60' http://169.254.169.254/latest/api/token 2>/dev/null)
SID=$(wget -qO- --header="X-metadata-token: $TOKEN" http://169.254.169.254/session_id 2>/dev/null)
[ -n "$SID" ] && echo "SESSION_ID=$SID" > /run/chatbot.env
EOF
chmod +x "$tmp/etc/local.d/mmds.start"

echo "== 4. ext4 に焼く(tar サイズ + 30% 余白) =="
sudo mkdir -p "$(dirname "$OUT")"
bytes="$(du -sb "$tmp" | cut -f1)"
mib="$(( (bytes / 1024 / 1024) * 13 / 10 + 64 ))"   # 余白 30% + 最低 64MiB
truncate -s "${mib}M" "$OUT"
mkfs.ext4 -q -F "$OUT"
mnt="$(mktemp -d)"
sudo mount -o loop "$OUT" "$mnt"
sudo cp -a "$tmp"/. "$mnt"/
sudo umount "$mnt"
rmdir "$mnt"
rm -rf "$tmp"

echo "完了: $OUT (${mib}MiB)"
echo "サイドバー: この 40 行が (1)-(5) を黙って処理した。イメージはビルドタイムの 1 回コスト。"
