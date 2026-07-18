#!/usr/bin/env bash
# Step 5: スナップショット/復元。AI エージェント運用の核心「セッションのコールドスタート」への答え。
#
# 単一 VM で boot → pause → snapshot → 別プロセスで load、復元時間を測る。
# 制約も同時に体感する:
#   - 復元側で tap を同名で再生成する必要がある(クローンは netns 迂回が要る)
#   - FC バージョン一致が安全基準線
#   - 時計は clock_realtime、VMGenID はカーネル PRNG を自動再シードするが
#     アプリ層の UUID/トークンは自前で振り直す必要がある
set -euo pipefail

STATE_DIR="${MVM_STATE_DIR:-/srv/mvm}"
KERNEL="${MVM_KERNEL:-${STATE_DIR}/vmlinux}"
BASE_ROOTFS="${MVM_ROOTFS:-${STATE_DIR}/rootfs.ext4}"
FC_BIN="${MVM_FC:-/usr/local/bin/firecracker}"
WORK="${STATE_DIR}/snap"; mkdir -p "$WORK"
TAP="fc-tap-snap"; HOST_IP=172.16.200.1; GUEST_IP=172.16.200.2; MASK=255.255.255.252
api() { curl -fsS --unix-socket "$1" -X PUT "http://localhost$2" -H 'content-type: application/json' -d "$3" >/dev/null; }

ip link del "$TAP" 2>/dev/null || true
ip tuntap add "$TAP" mode tap; ip addr add "${HOST_IP}/30" dev "$TAP"; ip link set "$TAP" up
cp --reflink=auto "$BASE_ROOTFS" "${WORK}/rootfs.ext4"

echo "== 1. base VM を起動 =="
sock="${WORK}/base.sock"; rm -f "$sock"
"$FC_BIN" --api-sock "$sock" &>"${WORK}/base.log" & echo $! > "${WORK}/base.pid"
for _ in $(seq 1 50); do [[ -S "$sock" ]] && break; sleep 0.05; done
api "$sock" /boot-source "{\"kernel_image_path\":\"${KERNEL}\",\"boot_args\":\"console=ttyS0 reboot=k panic=1 root=/dev/vda ip=${GUEST_IP}::${HOST_IP}:${MASK}::eth0:off\"}"
api "$sock" /drives/rootfs "{\"drive_id\":\"rootfs\",\"path_on_host\":\"${WORK}/rootfs.ext4\",\"is_root_device\":true}"
api "$sock" /network-interfaces/eth0 "{\"iface_id\":\"eth0\",\"guest_mac\":\"06:00:AC:10:C8:02\",\"host_dev_name\":\"${TAP}\"}"
api "$sock" /machine-config '{"vcpu_count":1,"mem_size_mib":128}'
api "$sock" /actions '{"action_type":"InstanceStart"}'
sleep 3   # ゲスト起動待ち

echo "== 2. pause してスナップショット作成(Full) =="
api "$sock" /vm '{"state":"Paused"}'
t0=$(date +%s.%N)
api "$sock" /snapshot/create "{\"snapshot_type\":\"Full\",\"snapshot_path\":\"${WORK}/vm.snap\",\"mem_file_path\":\"${WORK}/vm.mem\"}"
t1=$(date +%s.%N)
echo "snapshot 作成: $(echo "$t1 - $t0" | bc)s"
kill "$(cat "${WORK}/base.pid")" 2>/dev/null || true

echo "== 3. 別プロセスで復元(tap は同名で残っている前提) =="
sock2="${WORK}/restore.sock"; rm -f "$sock2"
"$FC_BIN" --api-sock "$sock2" &>"${WORK}/restore.log" & echo $! > "${WORK}/restore.pid"
for _ in $(seq 1 50); do [[ -S "$sock2" ]] && break; sleep 0.05; done
t2=$(date +%s.%N)
api "$sock2" /snapshot/load "{\"snapshot_path\":\"${WORK}/vm.snap\",\"mem_file_path\":\"${WORK}/vm.mem\",\"resume_vm\":true}"
t3=$(date +%s.%N)
echo "復元 + 再開: $(echo "$t3 - $t2" | bc)s   ← コールドブート(~125ms 公称)と比べよ"

echo "後始末: kill \$(cat ${WORK}/restore.pid); ip link del ${TAP}"
