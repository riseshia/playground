# 2 段ビルド: 静的バイナリを作り、それを Alpine + OpenRC の最小 rootfs に載せる。
# このイメージを build-rootfs.sh が `docker export` して ext4 に焼く。
#
# ポイント: rootfs を microVM で直接ブートするには PID1(init) と ttyS0 の getty が要る。
# Docker の CMD は init にならないので、ここで OpenRC を仕込んでおく。

# --- builder ---
FROM golang:1.23-alpine AS builder
WORKDIR /src
COPY main.go .
# 依存ゼロの単一ファイルなので go.mod なしで直接ビルド
RUN go mod init chatbot && CGO_ENABLED=0 go build -ldflags="-s -w" -o /chatbot main.go

# --- runtime rootfs ---
FROM alpine:3.20

# init と getty。openrc = PID1、agetty = ttyS0 のログインコンソール。
RUN apk add --no-cache openrc util-linux \
    && ln -s agetty /etc/init.d/agetty.ttyS0 \
    && echo ttyS0 > /etc/securetty \
    && rc-update add agetty.ttyS0 default \
    && rc-update add local default

# root パスワードを空に(ラボ用途のみ。シリアルから即ログインできるように)
RUN passwd -d root

COPY --from=builder /chatbot /usr/local/bin/chatbot

# chatbot を OpenRC サービスとして登録し、ブート時に自動起動する。
RUN mkdir -p /etc/init.d && cat > /etc/init.d/chatbot <<'EOF'
#!/sbin/openrc-run
name="chatbot"
command="/usr/local/bin/chatbot"
command_background=true
pidfile="/run/chatbot.pid"
output_log="/var/log/chatbot.log"
error_log="/var/log/chatbot.log"
depend() { need net; }
EOF
RUN chmod +x /etc/init.d/chatbot && rc-update add chatbot default

# このイメージは docker run で使うのではなく rootfs 抽出用。
# 動作確認したい場合のみ: docker run --rm -p 8080:8080 <image> /usr/local/bin/chatbot
CMD ["/usr/local/bin/chatbot"]
