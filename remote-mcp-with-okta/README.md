# Remote MCP Server with Okta OAuth

Okta를 OAuth Authorization Server로 사용하는 Remote MCP 서버입니다.

## 아키텍처

```
┌─────────────┐     ┌─────────────┐     ┌─────────┐
│ MCP Client  │────▶│ MCP Server  │────▶│  Okta   │
│ (Claude 등) │     │ (이 서버)   │     │  (AS)   │
└─────────────┘     └─────────────┘     └─────────┘
```

- **Transport**: Streamable HTTP (MCP 2025-03-26 스펙)
- **인증**: OAuth 2.0 Bearer Token (JWT)
- **JWT 검증**: 로컬에서 JWKS 캐싱 후 검증 (매 요청마다 Okta 호출 안 함)

## 설치

```bash
npm install
npm run build
```

## 환경 변수 설정

```bash
cp .env.example .env
```

`.env` 파일 편집:

```env
# Server Configuration
PORT=3000
SERVER_BASE_URL=https://your-server.example.com

# Okta OAuth Configuration
OKTA_ISSUER=https://your-okta-domain.okta.com/oauth2/your-auth-server-id
OKTA_AUDIENCE=https://your-server.example.com
```

| 변수 | 설명 | 예시 |
|------|------|------|
| `PORT` | 서버 포트 | `3000` |
| `SERVER_BASE_URL` | 클라이언트가 접근하는 외부 URL | `https://mcp.example.com` |
| `OKTA_ISSUER` | Okta Authorization Server URL | `https://dev-123456.okta.com/oauth2/default` |
| `OKTA_AUDIENCE` | 토큰의 audience 값 (보통 서버 URL) | `https://mcp.example.com` |

## Okta 설정 가이드

### 1. Authorization Server 생성/설정

**Security > API > Authorization Servers**

기존 `default` 서버를 사용하거나 새로 생성:

| 설정 | 값 |
|------|-----|
| Name | `MCP Server` (또는 원하는 이름) |
| Audience | `https://your-server.example.com` (SERVER_BASE_URL과 동일) |

생성 후 **Issuer URI**를 복사하여 `OKTA_ISSUER`에 설정합니다.

### 2. Scope 추가

**Authorization Server > Scopes > Add Scope**

| 설정 | 값 |
|------|-----|
| Name | `mcp:read` |
| Description | `MCP server read access` |
| Default scope | ✅ 체크 |

### 3. 클라이언트 앱 등록 (Claude Code용)

**Applications > Create App Integration**

```
Sign-in method:     OIDC - OpenID Connect
Application type:   Native Application
```

**General Settings:**

| 설정 | 값 |
|------|-----|
| App integration name | `Claude Code` (또는 원하는 이름) |
| Grant types | ✅ Authorization Code, ✅ Refresh Token |

**Sign-in redirect URIs:**

```
http://127.0.0.1/callback
http://localhost/callback
```

> **Note**: Claude Code는 로컬에 임시 HTTP 서버를 띄워서 OAuth callback을 받습니다.
> 정확한 redirect URI 패턴은 Claude Code 문서를 확인하세요.

**Assignments:**

- `Controlled access` > `Allow everyone in your organization` 또는 특정 그룹 지정

앱 생성 후 **Client ID**를 복사해둡니다 (Claude Code 설정에 필요할 수 있음).

### 4. Access Policy 설정

**Authorization Server > Access Policies**

기존 Default Policy를 사용하거나 새로 생성:

**Add Rule:**

| 설정 | 값 |
|------|-----|
| Rule Name | `MCP Access` |
| Grant types | ✅ Authorization Code |
| Scopes | `mcp:read` (또는 Any scopes) |

**Token Lifetimes (권장 설정):**

| 설정 | 값 | 설명 |
|------|-----|------|
| Access token lifetime | 1 hour | 표준적인 값 |
| Refresh token lifetime | Unlimited | 계속 사용하면 만료 안 됨 |
| Refresh token idle lifetime | 30 days | 30일 미사용 시 만료 |

> **Tip**: "Rotate refresh token after each use"를 활성화하면 보안이 강화됩니다.

## 서버 실행

```bash
# 빌드 후 실행
npm run build
npm start

# 또는 개발 모드
npm run dev
```

서버가 시작되면:
```
MCP Server running at http://localhost:3000
Health check: http://localhost:3000/health
OAuth metadata: http://localhost:3000/.well-known/oauth-protected-resource
MCP endpoint: http://localhost:3000/mcp
```

## Claude Code 설정

`~/.claude/settings.json` 또는 프로젝트의 `.claude/settings.json`:

```json
{
  "mcpServers": {
    "my-okta-mcp": {
      "url": "https://your-server.example.com/mcp"
    }
  }
}
```

URL만 설정하면 됩니다. OAuth 관련 설정은 서버의 메타데이터를 통해 자동으로 처리됩니다.

### 인증 흐름

1. Claude Code에서 MCP 도구 호출
2. 서버가 401 반환 → Claude Code가 OAuth 메타데이터 조회
3. 브라우저가 열리고 Okta 로그인 페이지 표시
4. 사용자가 로그인 + 권한 동의
5. Claude Code가 토큰을 받아서 저장
6. 이후 요청은 자동으로 토큰 사용 (재로그인 불필요)

## 테스트

### 1. Health Check

```bash
curl http://localhost:3000/health
```

응답:
```json
{"status":"ok"}
```

### 2. OAuth 메타데이터 확인

```bash
curl http://localhost:3000/.well-known/oauth-protected-resource
```

응답:
```json
{
  "resource": "https://your-server.example.com",
  "authorization_servers": ["https://your-okta-domain.okta.com/oauth2/..."],
  "scopes_supported": ["mcp:read"],
  "bearer_methods_supported": ["header"]
}
```

### 3. 인증 없이 요청 (401 확인)

```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

응답 헤더에 `WWW-Authenticate: Bearer resource="..."` 포함됨.

### 4. 토큰으로 요청

Okta에서 테스트 토큰을 발급받은 후:

```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <your-access-token>" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

### 5. ping 도구 호출

```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <your-access-token>" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"ping","arguments":{"message":"hello world"}}}'
```

응답:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [{"type": "text", "text": "pong: hello world"}]
  }
}
```

## AWS 배포 시 참고

```
┌──────────┐      ┌───────┐      ┌─────────────┐
│  Client  │─────▶│  ALB  │─────▶│ MCP Server  │
│ (Claude) │ HTTPS│ (TLS) │ HTTP │  (ECS/EC2)  │
└──────────┘  443 └───────┘  3000└─────────────┘
```

- **TLS Termination**: ALB에서 HTTPS 처리
- **Health Check**: `/health` 엔드포인트 사용
- **환경 변수**: AWS Secrets Manager 또는 Parameter Store 권장

## 엔드포인트 요약

| 경로 | 메서드 | 인증 | 설명 |
|------|--------|------|------|
| `/health` | GET | ❌ | 헬스체크 |
| `/.well-known/oauth-protected-resource` | GET | ❌ | OAuth 메타데이터 |
| `/mcp` | POST | ✅ | MCP JSON-RPC 요청 |
| `/mcp` | GET, DELETE | - | 405 (stateless 모드) |

## 라이선스

MIT
