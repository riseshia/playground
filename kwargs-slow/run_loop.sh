#!/usr/bin/env bash
set -euo pipefail

MAX_ITERATIONS="${1:-5}"
SRC="ruby_struct.rb"
TEST_CMD="ruby ruby_struct_test.rb"
BENCH_CMD="ruby bench_ruby_struct.rb"
PROFILE_CMD="ruby profile_ruby_struct.rb"
REPORT="REPORT.md"

# --- ベースライン計測 ---
echo "=== ベースライン計測 ==="

# ソースのスナップショットを保存
cp "$SRC" "${SRC}.baseline"

echo "[baseline] ベンチマーク実行中..."
BENCH_OUT=$($BENCH_CMD 2>&1) || true
echo "$BENCH_OUT"

echo ""
echo "[baseline] プロファイル実行中..."
PROFILE_OUT=$($PROFILE_CMD 2>&1) || true
echo "$PROFILE_OUT"

# REPORT.md 初期化
cat > "$REPORT" <<EOF
# RubyStruct 最適化レポート

## ベースライン

### ベンチマーク (benchmark/ips)
\`\`\`
${BENCH_OUT}
\`\`\`

### プロファイル (メモリ・CPU・GC)
\`\`\`
${PROFILE_OUT}
\`\`\`

---
EOF

echo ""
echo "=== Ralph Loop Start (max ${MAX_ITERATIONS} iterations) ==="

for i in $(seq 1 "$MAX_ITERATIONS"); do
  echo ""
  echo "=============================="
  echo "  Iteration ${i} / ${MAX_ITERATIONS}"
  echo "=============================="

  # 最適化前のソースを保存 (diff 用)
  cp "$SRC" "${SRC}.before_iter${i}"

  # Iteration ヘッダーを REPORT.md に追記
  cat >> "$REPORT" <<EOF

## Iteration ${i}

EOF

  # Claude に最適化を依頼
  echo "[${i}] Claude に最適化を依頼中..."

  PROMPT="ruby_struct.rb は Ruby の組み込み Struct クラスをプレーン Ruby で再実装したものです。
このコードを高速化してください。

## 制約
- ruby_struct.rb のみを編集してください。テストやベンチマークは変更しないでください。
- RubyStruct.new で返されるクラスの公開 API（メソッド名・引数・戻り値）は変えないでください。
- テスト (ruby ruby_struct_test.rb) が全て通ることを必ず確認してください。

## 最適化の方針
- class_eval による文字列ベースのメソッド定義を活用し、VM のインライン化・JIT 最適化に乗りやすいコードにする
- 不要なオブジェクト生成（配列・ハッシュの一時生成）を減らす
- define_singleton_method / define_method よりも class_eval 文字列の方が高速なため、可能な限りそちらを使う
- splat (*args, **kwargs) の利用を最小限にし、固定引数のメソッドシグネチャを生成する
- each/each_pair 等のイテレータでは yield を直接使い、ブロック呼び出しのオーバーヘッドを減らす

## 作業手順
1. まず REPORT.md を読み、ベースラインの数値と過去のイテレーションで試したアプローチ・結果を確認してください
2. ruby_struct.rb を読み、現在の実装を把握してください
3. REPORT.md のプロファイルデータを参考に、アロケーションが多い箇所やCPU時間が長いボトルネックを特定してください
4. 過去に試していない新しいアプローチで最適化を施した ruby_struct.rb を書き出してください
5. ruby ruby_struct_test.rb を実行し、全テストが通ることを確認してください
6. 最後に REPORT.md の「## Iteration ${i}」セクションに以下を追記してください:
   - ### アプローチ: 今回試した最適化手法の要約（箇条書き）
   - ### 変更点: 具体的なコード変更の説明

重要: REPORT.md を参照して、過去に試したアプローチと同じ手法を繰り返さないでください。
まだ試していない別の最適化アプローチを探ってください。"

  claude -p "$PROMPT"

  # テスト実行
  echo ""
  echo "[${i}] テスト実行中..."
  if ! $TEST_CMD; then
    echo "[${i}] テスト失敗！ループを中断します。"
    cat >> "$REPORT" <<EOF
### 結果: テスト失敗 — ループ中断
EOF
    exit 1
  fi
  echo "[${i}] テスト OK"

  # ベンチマーク実行 & キャプチャ
  echo ""
  echo "[${i}] ベンチマーク実行中..."
  BENCH_OUT=$($BENCH_CMD 2>&1) || true
  echo "$BENCH_OUT"
  echo "[${i}] ベンチマーク完了"

  # プロファイル実行 & キャプチャ
  echo ""
  echo "[${i}] プロファイル実行中..."
  PROFILE_OUT=$($PROFILE_CMD 2>&1) || true
  echo "$PROFILE_OUT"
  echo "[${i}] プロファイル完了"

  # diff を取得
  DIFF_OUT=$(diff -u "${SRC}.before_iter${i}" "$SRC" || true)

  # REPORT.md に結果を追記
  cat >> "$REPORT" <<EOF

### ベンチマーク結果
\`\`\`
${BENCH_OUT}
\`\`\`

### プロファイル結果
\`\`\`
${PROFILE_OUT}
\`\`\`

### コード差分
\`\`\`diff
${DIFF_OUT}
\`\`\`

---
EOF

  echo "[${i}] REPORT.md 更新完了"

  # スナップショットの掃除
  rm -f "${SRC}.before_iter${i}"
done

# ベースラインのスナップショットを掃除
rm -f "${SRC}.baseline"

echo ""
echo "=== Ralph Loop 完了 (${MAX_ITERATIONS} iterations) ==="
echo "レポート: ${REPORT}"
