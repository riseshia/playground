#!/usr/bin/env bash
# Step 3: ホスト側ネットワーク(NAT + FORWARD)を一度だけ用意する。
# per-VM の tap は mvm が個別に作る。ここは「全 microVM 共通の egress 経路」だけ。
#
# 罠 #3(最頻): 同じホストで Docker を使っていると iptables の FORWARD ポリシーが DROP。
# ゲストは IP を取れるのに egress だけ死ぬ、という切り分けにくい症状になる。
set -euo pipefail

# 外向き NIC を自動検出(既定ルートのデバイス)
UPLINK="${UPLINK:-$(ip route show default | awk '/default/{print $5; exit}')}"
echo "uplink = ${UPLINK}"

echo "== IP forwarding を有効化 =="
sudo sysctl -w net.ipv4.ip_forward=1

echo "== microVM サブネット(172.16.0.0/16)を MASQUERADE =="
# 既に同じルールが無ければ追加(冪等)
sudo iptables -t nat -C POSTROUTING -s 172.16.0.0/16 -o "$UPLINK" -j MASQUERADE 2>/dev/null \
  || sudo iptables -t nat -A POSTROUTING -s 172.16.0.0/16 -o "$UPLINK" -j MASQUERADE

echo "== FORWARD を許可(Docker の DROP ポリシー対策) =="
sudo iptables -C FORWARD -s 172.16.0.0/16 -j ACCEPT 2>/dev/null \
  || sudo iptables -I FORWARD 1 -s 172.16.0.0/16 -j ACCEPT
sudo iptables -C FORWARD -d 172.16.0.0/16 -j ACCEPT 2>/dev/null \
  || sudo iptables -I FORWARD 1 -d 172.16.0.0/16 -j ACCEPT

echo "完了。"
echo "警告: docker daemon を再起動すると FORWARD ルールが飛ぶことがある。その時はこれを再実行。"
