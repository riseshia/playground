// generic agent chatbot — microVM 세션 격리 랩용 샘플 앱
//
// "세션별 에이전트가 임의 명령을 실행한다"는 시나리오를 가장 얇게 재현한다.
//   POST /run   {"cmd": "..."}  → sh -c 로 실행하고 stdout/stderr/exit code 반환
//   GET  /health               → 세션 식별자와 uptime 반환
//
// 의도적으로 안전장치가 없다(임의 셸 실행). 이 앱을 "신뢰할 수 없는 코드"로 간주하고,
// 격리 경계는 앱이 아니라 microVM(그리고 그 바깥의 오케스트레이터)이 책임진다는 게 이 랩의 전제다.
//
// CGO_ENABLED=0 で静的ビルドし、rootfs には依存ゼロのバイナリ 1 個だけ入れる。
package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"time"
)

var (
	startedAt = time.Now()
	// セッション ID は MMDS 経由で注入する想定（Step 4b 参照）。
	// 未注入なら "unknown" を返す。
	sessionID = getenvOr("SESSION_ID", "unknown")
)

type runRequest struct {
	Cmd string `json:"cmd"`
}

type runResponse struct {
	Stdout   string `json:"stdout"`
	Stderr   string `json:"stderr"`
	ExitCode int    `json:"exit_code"`
}

func main() {
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{
			"session_id": sessionID,
			"uptime_sec": int(time.Since(startedAt).Seconds()),
		})
	})

	http.HandleFunc("/run", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "POST only"})
			return
		}
		var req runRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Cmd == "" {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "expected {\"cmd\": \"...\"}"})
			return
		}

		// あえて sh -c にそのまま渡す（サンドボックス境界は microVM 側）。
		cmd := exec.Command("sh", "-c", req.Cmd)
		var stdout, stderr []byte
		out, err := cmd.Output()
		stdout = out
		exitCode := 0
		if ee, ok := err.(*exec.ExitError); ok {
			stderr = ee.Stderr
			exitCode = ee.ExitCode()
		} else if err != nil {
			stderr = []byte(err.Error())
			exitCode = -1
		}

		writeJSON(w, http.StatusOK, runResponse{
			Stdout:   string(stdout),
			Stderr:   string(stderr),
			ExitCode: exitCode,
		})
	})

	addr := getenvOr("LISTEN_ADDR", ":8080")
	fmt.Printf("chatbot listening on %s (session=%s)\n", addr, sessionID)
	if err := http.ListenAndServe(addr, nil); err != nil {
		fmt.Fprintln(os.Stderr, "server error:", err)
		os.Exit(1)
	}
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func getenvOr(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}
