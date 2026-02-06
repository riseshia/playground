# Remote MCP Server with AWS Cognito OAuth

AWS Cognito를 OAuth Authorization Server로 사용하는 Remote MCP 서버입니다.

## 아키텍처

```
┌─────────────┐     ┌─────────────┐     ┌─────────┐
│ MCP Client  │────▶│ MCP Server  │────▶│Cognito  │
│ (Claude 등) │     │ (이 서버)   │     │  (AS)   │
└─────────────┘     └─────────────┘     └─────────┘
```

- **Transport**: Streamable HTTP (MCP 2025-03-26 스펙)
- **인증**: OAuth 2.0 Bearer Token (JWT)
- **JWT 검증**: 로컬에서 JWKS 캐싱 후 검증 (매 요청마다 Cognito 호출 안 함)

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

# AWS Cognito OAuth Configuration
COGNITO_USER_POOL_ID=ap-northeast-1_YourPoolId
COGNITO_REGION=ap-northeast-1
COGNITO_CLIENT_ID=your-app-client-id
```

| 변수 | 설명 | 예시 |
|------|------|------|
| `PORT` | 서버 포트 | `3000` |
| `SERVER_BASE_URL` | 클라이언트가 접근하는 외부 URL | `https://mcp.example.com` |
| `COGNITO_USER_POOL_ID` | Cognito User Pool ID | `ap-northeast-1_AbCdEfGhI` |
| `COGNITO_REGION` | Cognito가 위치한 AWS 리전 | `ap-northeast-1` |
| `COGNITO_CLIENT_ID` | Cognito App Client ID | `1a2b3c4d5e6f7g8h9i0j` |

## Cognito 설정 가이드

### 1. User Pool 생성

**Amazon Cognito > User Pools > Create user pool**

주요 설정:

| 설정 | 값 |
|------|-----|
| Sign-in options | Email (또는 필요에 따라) |
| Password policy | 요구사항에 맞게 설정 |
| MFA | 필요에 따라 설정 |

### 2. App Client 생성

**User Pool > App integration > Create app client**

| 설정 | 값 |
|------|-----|
| App type | Public client |
| App client name | `Claude Code` (또는 원하는 이름) |
| Authentication flows | `ALLOW_USER_SRP_AUTH`, `ALLOW_REFRESH_TOKEN_AUTH` |
| OAuth 2.0 Grant types | Authorization code grant |
| Allowed callback URLs | `http://127.0.0.1/callback`, `http://localhost/callback` |
| Allowed sign-out URLs | (필요에 따라) |

> **Note**: Claude Code는 로컬에 임시 HTTP 서버를 띄워서 OAuth callback을 받습니다.

생성 후 **Client ID**를 복사하여 `COGNITO_CLIENT_ID`에 설정합니다.

### 3. Domain 설정

**User Pool > App integration > Domain**

Cognito domain 또는 Custom domain을 설정합니다:

```
https://your-domain.auth.ap-northeast-1.amazoncognito.com
```

### 4. Resource Server 생성

**User Pool > App integration > Resource servers > Create resource server**

| 설정 | 값 |
|------|-----|
| Resource server name | `MCP Server` |
| Resource server identifier | `mcp` |
| Custom scopes | `read` (scope name: `mcp/read`) |

### 5. App Client에 Scope 할당

**App client > Hosted UI > Edit**

- OAuth scope에 `mcp/read`를 추가

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
    "my-cognito-mcp": {
      "url": "https://your-server.example.com/mcp"
    }
  }
}
```

URL만 설정하면 됩니다. OAuth 관련 설정은 서버의 메타데이터를 통해 자동으로 처리됩니다.

### 인증 흐름

1. Claude Code에서 MCP 도구 호출
2. 서버가 401 반환 → Claude Code가 OAuth 메타데이터 조회
3. 브라우저가 열리고 Cognito 로그인 페이지 표시
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
  "authorization_servers": ["https://cognito-idp.ap-northeast-1.amazonaws.com/ap-northeast-1_YourPoolId"],
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

Cognito에서 테스트 토큰을 발급받은 후:

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
