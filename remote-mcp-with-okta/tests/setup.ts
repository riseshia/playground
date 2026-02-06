import { vi } from 'vitest';

// テスト用環境変数
process.env.COGNITO_USER_POOL_ID = 'ap-northeast-1_TestPool123';
process.env.COGNITO_REGION = 'ap-northeast-1';
process.env.COGNITO_CLIENT_ID = 'test-client-id';
process.env.SERVER_BASE_URL = 'http://localhost:3000';

// jsonwebtoken mock
vi.mock('jsonwebtoken', () => {
  return {
    default: {
      decode: (token: string) => {
        if (token === 'valid-token' || token === 'expired-token' || token === 'invalid-token') {
          return {
            header: { kid: 'test-kid', alg: 'RS256' },
            payload: { sub: 'user@example.com' },
          };
        }
        return null;
      },
      verify: (token: string) => {
        if (token === 'valid-token') {
          return {
            sub: 'user@example.com',
            iss: 'https://cognito-idp.ap-northeast-1.amazonaws.com/ap-northeast-1_TestPool123',
            token_use: 'access',
            scope: 'openid email',
          };
        }
        if (token === 'expired-token') {
          throw new Error('jwt expired');
        }
        throw new Error('invalid signature');
      },
    },
  };
});

// jwk-to-pem mock
vi.mock('jwk-to-pem', () => {
  return {
    default: () => 'mock-pem-key',
  };
});

// global fetch mock for JWKS and metadata
const originalFetch = global.fetch;
global.fetch = vi.fn(async (url: string | URL | globalThis.Request) => {
  const urlStr = url.toString();

  if (urlStr.includes('openid-configuration')) {
    return new Response(JSON.stringify({
      issuer: 'https://cognito-idp.ap-northeast-1.amazonaws.com/ap-northeast-1_TestPool123',
      jwks_uri: 'https://cognito-idp.ap-northeast-1.amazonaws.com/ap-northeast-1_TestPool123/.well-known/jwks.json',
      authorization_endpoint: 'https://test.auth.ap-northeast-1.amazoncognito.com/oauth2/authorize',
      token_endpoint: 'https://test.auth.ap-northeast-1.amazoncognito.com/oauth2/token',
    }));
  }

  if (urlStr.includes('jwks.json')) {
    return new Response(JSON.stringify({
      keys: [{ kid: 'test-kid', kty: 'RSA', n: 'test', e: 'AQAB' }],
    }));
  }

  return originalFetch(url);
}) as typeof fetch;
