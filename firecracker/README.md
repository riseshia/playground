# Firecracker microVM 세션 격리 랩

> "agent 챗봇을 세션마다 microVM으로 격리 실행"을 맨손으로 만들어보며,
> **진짜 비용이 어디에 있는지** 몸으로 확인하는 실습 코스.

## 이 랩이 답하는 질문

컨테이너보다 강한 격리가 필요한 워크로드(예: 신뢰할 수 없는 코드를 실행하는 AI 에이전트)를
**직접 만든 Firecracker 오케스트레이터**로 굴리는 게 유지보수할 만한가?

흔한 착각: *"rootfs 이미지만 만들면 거의 끝난 거 아냐?"*
이 랩의 결론(스포일러): **이미지는 빌드타임 1회 비용, 오케스트레이션(네트워킹·라이프사이클·후처리)은 세션마다 반복되는 런타임 비용이다.** 그 체감을 얻는 게 목표.

## 전제

- **Linux 호스트 + `/dev/kvm`.** macOS/Windows 로컬은 안 됨(중첩 가상화 이슈). 아래 중 하나:

  | 환경 | KVM 확보 방법 | 비고 |
  |---|---|---|
  | AWS `*.metal` | 베어메탈, 바로 사용 | 확실하지만 비쌈 |
  | AWS C8i/M8i/R8i | `NestedVirtualization=enabled` (2026-02~) | 중형+ 인스턴스, x86만, 베어메탈보다 저렴 |
  | GCP | nested virt 플래그 | CPU 10%+ 오버헤드 |
  | Hetzner 등 | 베어메탈 시간당 임대 | 저비용 대안 |

- x86_64 기준으로 작성. arm64는 각 스텝의 arm 주석 참조.
- `docker`, `curl`, `iptables`, `iproute2` 설치돼 있을 것.

## 구성

```
firecracker/
├── README.md              # 이 문서 (0~5단계 + 부록)
├── scripts/
│   ├── 00-prereqs.sh      # KVM 확인 + FC/jailer/커널 취득
│   ├── build-rootfs.sh    # Docker 이미지 → ext4 rootfs (Step 2)
│   ├── net-setup.sh       # 호스트 NAT/FORWARD (Step 3)
│   ├── mvm                # 세션 오케스트레이터 create|list|destroy|gc (Step 4) ★본체
│   └── snapshot-demo.sh   # 스냅샷/복원 (Step 5)
├── chatbot/               # 샘플 agent 챗봇 (Go 정적 바이너리 + Dockerfile)
└── demos/                 # 격리 실증: forkbomb / rmrf / egress
```

> 주의: 스크립트는 **리눅스에서 검증하며 다듬는 골격**이다. 커널 CI 경로(`00-prereqs.sh`의 `CI_PREFIX`) 등 일부는 실제 호스트에서 실존 경로 확인이 필요하다(주석에 `Guess` 표기).

버전 핀: **Firecracker v1.16.1**. 가이드가 썩지 않게 `00-prereqs.sh` 상단에서만 버전을 관리한다.

---

## Step 0 — 사전준비 & KVM 확인  ⏱ 30–60분

```bash
sudo ./scripts/00-prereqs.sh
```

`/dev/kvm` 확인 → `firecracker`/`jailer` 바이너리 설치 → 게스트 커널(`vmlinux`) 취득.

> 🕳 **래빗홀 #1 — 클라우드 인스턴스 선택.** 위 표에서 고르되, **30분 넘게 헤매면** 그냥 `.metal`이나 Hetzner 베어메탈로 갈아타라. nested virt 삽질은 이 랩의 학습 목표가 아니다.

---

## Step 1 — 첫 microVM 맨손 부팅  ⏱ 45–60분

여기선 **일부러 스크립트를 안 쓰고** REST API를 직접 친다. Firecracker의 제어 모델(유닉스 소켓 + PUT)을 손끝으로 익히는 게 목적. (아직 rootfs가 없으니 CI의 prebuilt ubuntu rootfs를 임시로 받아 쓴다 — `00-prereqs.sh`의 S3 경로 참고.)

```bash
API=/tmp/fc.sock; rm -f $API
firecracker --api-sock $API &

put() { curl -fsS --unix-socket $API -X PUT "http://localhost$1" -H 'content-type: application/json' -d "$2"; }

# 罠 #1: console=ttyS0 が無いとカーネルが何も出力しない。pci=off は v1.16 では入れない。
put /boot-source '{"kernel_image_path":"/srv/mvm/vmlinux","boot_args":"console=ttyS0 reboot=k panic=1 root=/dev/vda"}'
put /drives/rootfs '{"drive_id":"rootfs","path_on_host":"/srv/mvm/ubuntu.ext4","is_root_device":true}'
put /machine-config '{"vcpu_count":1,"mem_size_mib":128}'
put /actions '{"action_type":"InstanceStart"}'
```

시리얼 콘솔에 커널 로그가 흐르고 로그인 프롬프트가 뜨면 성공. `reboot`으로 종료하면 Firecracker가 우아하게 꺼진다.

> 🕳 **함정 상위 5개 중 #1, #6:** `console=ttyS0`(무출력의 주범), `root=/dev/vda`(sda 아님, virtio-blk).

---

## Step 2 — Docker 이미지로 rootfs 굽기  ⏱ 45–90분

```bash
sudo ./scripts/build-rootfs.sh fc-chatbot:latest /srv/mvm/rootfs.ext4
```

`chatbot/`을 빌드 → `docker export` → ext4로 변환. **이 스텝은 일부러 쉽다.**

> 📎 **사이드바 — 스크립트가 조용히 고친 것.** 素の `docker export`는 microVM에서 반드시 panic한다. FC 부팅 고유의 함정 셋:
> 1. **PID1(init) 부재** → `Attempted to kill init` 패닉. OpenRC로 해결.
> 2. **ttyS0 getty 부재** → 시리얼 로그인 불가. `agetty.ttyS0` 등록.
> 3. **root 패스워드** → `passwd -d root`.
>
> 나머지 둘(`/etc/resolv.conf` 부재, ext4 사이징)은 리눅스 기본이라 상세는 → [`docs/linux-host-notes.md`](docs/linux-host-notes.md).
>
> 핵심: 이것들은 **한 번 스크립트화하면 끝**이다. "이미지가 어렵다"는 인상은 여기서 몇 시간 태울 때 생기는 착시 — 스크립트로 봉인했으니 진짜 비용은 다음 단계에 있다.

> 🕳 **커널 자가 컴파일 금지.** CI `vmlinux`를 써라. 정 하려면 `CONFIG_VIRTIO_MMIO/BLK/NET=y` + `CONFIG_VIRTIO_MMIO_CMDLINE_DEVICES=y`가 필요 — 최대 래빗홀이니 타임박스.

---

## Step 3 — 네트워킹  ⏱ 60–90분

```bash
sudo ./scripts/net-setup.sh   # 호스트 공통 NAT/FORWARD (1회)
```

첫 번째 진짜 마찰 지점. tap 디바이스 + bridge/NAT로 게스트가 도달 가능하고 밖으로 나갈 수 있게.

> 🕳 **래빗홀 #2 & 함정 #3 — Docker의 iptables FORWARD DROP.** rootfs 빌드에 Docker를 쓰므로 거의 확실히 밟는다(게스트가 IP는 받는데 **egress만 죽음**). `net-setup.sh`가 대응하지만 docker 재시작 시 날아가니 그때 재실행. 증상별 점검표와 `ip=` 파라미터 형식은 → [`docs/linux-host-notes.md`](docs/linux-host-notes.md#네트워킹-nat--forward).

---

## Step 4a — N세션 동시 기동  ⏱ (4a+4b 합쳐) 2.5–4시간

```bash
sudo ./scripts/mvm create 1
sudo ./scripts/mvm create 2
sudo ./scripts/mvm create 3
sudo ./scripts/mvm list
curl -s http://172.16.1.2:8080/health   # 세션 1
curl -s http://172.16.2.2:8080/health   # 세션 2
```

`mvm`이 세션 = microVM. **id에서 tap 이름·MAC·/30 서브넷을 결정론적으로 파생**해 충돌을 막는다.

> 🕳 **함정 #4 — N번째 VM의 MAC/IP/tap 충돌.** 설정 JSON을 복붙하면 반드시 터진다. `mvm`의 `derive_net()`이 이걸 어떻게 푸는지 읽어봐라.

**줄 수를 세어보라:** `mvm`에서 실제 부팅 API 호출은 `create()` 안의 ~15줄. 나머지 전부가 네트워크 파생 + 라이프사이클 + 후처리다. **이게 이 랩의 핵심 장면.**

---

## Step 4b — 라이프사이클 & GC (카오스 연습)  ⏱ 위에 포함

```bash
# 정상 회수
sudo ./scripts/mvm destroy 3

# ★ 카오스: FC를 강제로 죽여본다
PID=$(cat /srv/mvm/2/fc.pid); sudo kill -9 $PID
sudo ./scripts/mvm list           # 2번이 DEAD로 뜸
ip -o link | grep fc-tap          # tap이 고아로 남아있음 (FC는 자기 tap을 안 지운다)
sudo ./scripts/mvm gc             # 고아 tap/socket/dir 청소
```

> 🕳 **가장 중요한 교훈.** Firecracker는 **설계상** 자기 소켓/tap을 정리하지 않는다(공식 getting-started 스크립트에도 `rm -f $API_SOCKET`이 박혀 있음). 즉 **오케스트레이터의 본체는 행복 경로가 아니라 크래시 경로**다. 방금 `kill -9` 후 남은 잔해를 직접 목격한 것 — 이걸 자동으로 치우는 코드가 프로덕션 오케스트레이터 분량의 절반이다.

> 🕳 **함정 #5 — 잔존 소켓/tap → "Address already in use".** 그래서 `mvm`의 모든 시작 경로에 `rm -f` + `ip link del || true`가 선행한다.

---

## Step 4c — 세션 스토리지 전략  ⏱ 60–90분

지금 `mvm`은 세션마다 `cp --reflink=auto base.ext4`로 rootfs를 복제한다. 이게 스토리지 관점의 핵심 갈림길이다.

- **reflink이 먹으면**(Btrfs/XFS reflink, 같은 FS 내) CoW라 즉시 + 공간 공유. **안 먹으면 풀 카피** → 세션 수 × rootfs 크기만큼 **디스크가 단조 증가**한다. 파일시스템에 운명이 갈린다.

FC는 raw block device만 받는다(qcow2 미지원). 그래서 실전 CoW 선택지는:

| 방식 | 요지 | 트레이드오프 |
|---|---|---|
| **게스트 내 overlayfs** | base.ext4를 read-only 드라이브 + 빈 rw 드라이브 2개로 붙이고, 게스트 init이 `overlay` mount. 세션 종료 시 rw 드라이브만 폐기 | 가장 단순. base 공유 확실. 게스트 init 한 줄 추가 필요 |
| **dm-thin (device-mapper thin pool)** | 호스트에서 base의 thin snapshot을 세션마다 발급 | `firecracker-containerd`가 쓰는 방식. 설정 무겁지만 밀도 최고 |
| **dm-snapshot / reflink cp** | 현 `mvm` 방식 | 쉽지만 FS 의존, 회수 정책을 직접 짜야 |

**실습:** 게스트 overlayfs 방식으로 `mvm`을 고쳐, base는 read-only로 공유하고 세션별 diff만 남게 만들어라. 그리고 `du -sh` 로 세션 10개 띄웠을 때 디스크가 **선형 증가하지 않는지** 확인.

> 🕳 **핵심 — "디스크 단조 증가"는 스토리지 백엔드가 아니라 오케스트레이터가 막는다.** 세션 종료 = diff 폐기, 유휴 세션 = 스냅샷 후 회수. 이 회수 정책 역시 청구서에 올라간다(Step 4b의 GC와 같은 성격). "이미지만 되면 끝"이 아닌 이유가 또 하나.

---

## Step 5 — 스냅샷 / 복원  ⏱ 30–45분 (단일 VM 한정)

```bash
sudo ./scripts/snapshot-demo.sh
```

AI 에이전트 운용의 핵심 질문 "세션 콜드스타트"에 대한 답. boot→pause→snapshot→복원 시간을 직접 측정하고, 콜드부트(~125ms 공칭)와 비교하라.

> 제약도 교훈이다: 복원 시 **tap을 동일 이름으로 재생성**해야 하고, **FC 버전 일치**가 안전 기준선이며, **앱 레벨 UUID/토큰은 스냅샷 복제 시 자동으로 안 바뀐다**(VMGenID가 커널 PRNG는 재시드하지만 그 위는 네 몫). 복원 수치는 환경마다 다르니 "직접 재보라".

---

## 부록 A — jailer 하드닝 미리보기  ⏱ 45–60분 (VM 1개만)

메인 경로(1~4)에서 jailer를 뺀 건 흐름을 위해서지, 안 중요해서가 아니다. **신뢰 불가 코드 격리가 진짜 동기라면 프로덕션에선 jailer가 사실상 필수**(FC 보안 모델의 전제).

VM 1개만 jailer로 띄워보라. 그러면 알게 된다:
- chroot 안에 커널/rootfs를 **하드링크로 직접 넣어야** 함 (자동 복사 안 됨)
- API 소켓이 chroot 내부 경로(`<chroot>/run/firecracker.socket`)로 이동 → 지금까지의 스크립트가 전부 깨짐
- 최신 배포판은 `--cgroup-version 2` 플래그 필수
- 메모리 cgroup 제한 → 게스트 OOM 데모까지 얹으면 밀도 좋음

> 교훈 강화: **지금 만든 `mvm`의 모든 경로/권한 로직을 jailer chroot 기준으로 다시 짜야 한다. 그것도 오케스트레이션 청구서에 올라간다.**

---

## 격리 실증 (아무 세션에나)

```bash
./demos/forkbomb.sh 172.16.1.2   # ① fork bomb → 그 VM만 죽고 호스트/타세션 무사
./demos/rmrf.sh    172.16.1.2   # ② rm -rf / → 그 세션 rootfs 사본만 소실
./demos/egress.sh  172.16.1.2   # ③ 외부 도달 + "FC는 트래픽을 필터 안 한다"는 경고
```

> ③의 교훈: **FC는 게스트 트래픽을 전혀 필터링하지 않는다.** 게스트→호스트/메타데이터 엔드포인트 차단은 오케스트레이터(iptables) 몫. 격리는 공짜가 아니다.

---

## 회고  ⏱ 30분

직접 "고통 순위"를 써보라 — 어디서 시간을 제일 많이 태웠나? 이미지였나, 아니면 네트워크·라이프사이클·후처리였나?

**자작 vs 기존 레이어 (2026-07 생태계 현황):**
- `firecracker-containerd` — 사실상 저활동 유지보수(릴리스 태그 없음).
- Kata Containers + FC — virtio-fs 부재로 devmapper 필수, Kata 진영은 Cloud Hypervisor/Dragonball 쪽으로 이동 중.
- `flintlock` — Weaveworks 폐업 후 커뮤니티 유지(v0.9.0, 2025-11).
- **AI 에이전트 샌드박스 레퍼런스로는 [E2B](https://github.com/e2b-dev)** (오픈소스·셀프호스트 가능, FC 기반)가 현행 정답에 가깝다. 관리형은 Fly Machines, AWS Lambda MicroVMs(2026).
- `firectl` — 릴리스가 2022년에 멈춤. 쓰지 마라(어차피 raw API 직접 치는 게 이 랩의 요점).

### 소스로 더 파고들기 (Rust)

Firecracker는 Rust다. 자작 여부를 진지하게 판단하려면 "내가 친 REST API가 내부에서 뭘 하는지"를 코드로 보는 게 제일 빠르다. **Rust가 주력이 아니어도 따라갈 수 있는 경로만** 골랐다 — Step 1에서 친 API가 흐르는 순서 그대로다:

1. `src/firecracker/src/main.rs` — 진입점. API 서버를 띄우고 VMM 스레드를 건다.
2. `src/vmm/src/rpc_interface.rs` — HTTP 요청 → `VmmAction` 디스패치. `PUT /boot-source`가 여기서 무슨 내부 호출로 바뀌는지 보인다. (로직 위주, `unsafe` 거의 없음)
3. `src/vmm/src/resources.rs` + `builder.rs` — 설정이 누적됐다가 `build_microvm`으로 실제 VM이 조립되는 지점. 님의 `mvm` 셸이 curl로 하던 걸 FC가 내부에서 뭘 하며 받는지.
4. 곁들이면 좋은 국소 모듈: `src/vmm/src/mmds/`(세션 주입), `src/vmm/src/rate_limiter/`.

> ⛔ **지금은 스킵:** `src/vmm/src/vstate/`(vcpu, KVM `ioctl`, `unsafe` 덩어리), `src/vmm/src/arch/`(아키텍처별 저수준). 여긴 Rust + 가상화 둘 다 익숙해진 뒤에.

**판단 프롬프트:** 방금 만든 `mvm`(~200줄)이 "이 용도로만 좁힌" 최소 오케스트레이터다. 여기에 jailer 하드닝 + egress 필터 + 스냅샷 풀 + 디스크 GC 정책을 더한 걸 **네가 계속 멘테할 수 있겠는가?** 아니면 E2B 같은 걸 셀프호스트하는 게 나은가? — 이 랩을 마친 지금은 근거를 갖고 답할 수 있을 것이다.
