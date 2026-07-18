#!/usr/bin/env bash
# Step 0: KVM 確認 + Firecracker/jailer バイナリ取得 + ゲストカーネル取得。
# public repo にコミットされる教材なので、バージョンはピン留めする(latest を追うと腐る)。
set -euo pipefail

# --- バージョンピン(2026-07 時点の安定版。更新時はここだけ変える) ---
FC_VERSION="v1.16.1"
# CI アーティファクトの prefix は FC 本体のバージョンとは別管理。
# 実際のパスは https://s3.amazonaws.com/spec.ccfc.min?list-type=2&prefix=firecracker-ci/ で確認せよ。
CI_PREFIX="firecracker-ci/v1.12"   # Guess: Linux 上で実在パスを要確認

ARCH="$(uname -m)"          # x86_64 / aarch64
S3="https://s3.amazonaws.com/spec.ccfc.min"
DEST="${MVM_STATE_DIR:-/srv/mvm}"
sudo mkdir -p "$DEST"

echo "== 1. /dev/kvm を確認 =="
if [[ ! -e /dev/kvm ]]; then
  echo "ERROR: /dev/kvm がない。ベアメタル or nested-virt 有効なホストで実行すること。" >&2
  exit 1
fi
if [[ ! -w /dev/kvm ]]; then
  echo "WARN: /dev/kvm に書き込めない。次を実行して再ログイン: sudo usermod -aG kvm \$USER" >&2
fi
echo "OK: $(ls -l /dev/kvm)"

echo "== 2. firecracker + jailer を取得(${FC_VERSION}, ${ARCH}) =="
url="https://github.com/firecracker-microvm/firecracker/releases/download/${FC_VERSION}"
tmp="$(mktemp -d)"
curl -fsSL "${url}/firecracker-${FC_VERSION}-${ARCH}.tgz" | tar -xz -C "$tmp"
# tgz 展開後は release-<ver>-<arch>/{firecracker,jailer}-<ver>-<arch>
sudo install -m0755 "$tmp"/release-*/firecracker-* /usr/local/bin/firecracker
sudo install -m0755 "$tmp"/release-*/jailer-*      /usr/local/bin/jailer
rm -rf "$tmp"
firecracker --version | head -1
jailer --version | head -1

echo "== 3. ゲストカーネル(vmlinux)を取得 =="
# 最新の vmlinux を CI から拾う。腐り対策で取得後のファイル名をログに残す。
kernel_key="$(curl -fsSL "${S3}?list-type=2&prefix=${CI_PREFIX}/${ARCH}/vmlinux-&delimiter=/" \
  | grep -oE "${CI_PREFIX}/${ARCH}/vmlinux-[0-9.]+" | sort -V | tail -1 || true)"
if [[ -z "$kernel_key" ]]; then
  echo "ERROR: CI から vmlinux を見つけられなかった。CI_PREFIX を実在パスに直せ。" >&2
  echo "  確認: curl -s '${S3}?list-type=2&prefix=firecracker-ci/&delimiter=/'" >&2
  exit 1
fi
sudo curl -fsSL -o "${DEST}/vmlinux" "${S3}/${kernel_key}"
echo "OK: ${kernel_key} -> ${DEST}/vmlinux"

echo
echo "完了。次は Step 1(手動ブート)へ。rootfs はまだ無いので Step 2 で焼く。"
