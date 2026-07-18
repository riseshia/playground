# 호스트 기초 노트 (본문에서 분리)

> README 본문은 Firecracker 고유 지식에 집중하고, 리눅스/Docker/네트워킹 일반 지식은 여기로 뺐다.
> 이미 아는 내용이면 건너뛰어도 된다. 리눅스 호스트에서 막혔을 때 참조용.

## rootfs: `docker export` → ext4

`build-rootfs.sh`가 하는 일의 기초 부분.

- **`docker export`는 파일시스템 tar만 뽑는다.** 런타임에 Docker가 bind-mount하던 것들(`/etc/resolv.conf`, `/etc/hosts`, `/etc/hostname`)은 **이미지에 없다.** 그래서 스크립트가 `resolv.conf`를 직접 써 넣는다.
- **ext4 사이징** — tar 실제 크기 + 여백(+30%, 최소 64MiB)을 `truncate`로 잡고 `mkfs.ext4`. 여백이 없으면 게스트가 부팅 후 쓰기에서 `No space left`.
  ```bash
  bytes=$(du -sb rootfs_dir | cut -f1)
  mib=$(( bytes/1024/1024 * 13/10 + 64 ))
  truncate -s "${mib}M" rootfs.ext4 && mkfs.ext4 -q -F rootfs.ext4
  ```
- 나중에 키우려면 `truncate -s +512M rootfs.ext4 && e2fsck -f rootfs.ext4 && resize2fs rootfs.ext4`.

## 네트워킹: NAT + FORWARD

`net-setup.sh`가 하는 일의 기초 부분.

- **MASQUERADE** — microVM 서브넷(172.16.0.0/16) 출발 패킷을 업링크 NIC IP로 SNAT. 이게 있어야 게스트가 밖으로 나간다.
- **`net.ipv4.ip_forward=1`** — 호스트가 라우터 역할을 하도록.
- **Docker의 FORWARD DROP 함정** — Docker 데몬은 시작 시 `iptables`의 `FORWARD` 체인 기본 정책을 `DROP`으로 바꾼다. tap→업링크 전달이 이 정책에 걸려 죽는다.

  | 증상 | 점검 명령 |
  |---|---|
  | egress 안 됨 (IP는 있음) | `sudo iptables -L FORWARD -n \| head` — 정책이 DROP인가? |
  | 게스트가 IP 자체를 못 받음 | 부팅 `boot_args`의 `ip=` 파라미터 형식 확인 |
  | ping은 되는데 이름 해석 안 됨 | 게스트 `/etc/resolv.conf` |

  → `net-setup.sh`가 `172.16.0.0/16`에 대한 FORWARD ACCEPT를 최상단(`-I FORWARD 1`)에 넣어 우회한다. **docker 데몬을 재시작하면 규칙이 다시 날아갈 수 있으니** 그때 `net-setup.sh`를 재실행.

### 커널 `ip=` 부팅 파라미터 형식

`mvm`이 게스트 IP를 부팅 시점에 자동 설정하는 데 쓰는 커널 옵션:

```
ip=<client-ip>:<server>:<gateway>:<netmask>:<hostname>:<device>:<autoconf>
예) ip=172.16.1.2::172.16.1.1:255.255.255.252::eth0:off
```

`<server>`(NFS용)는 비우고, `<gateway>`에 호스트 tap IP, `<autoconf>`는 `off`(정적).
