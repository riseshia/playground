import { vi } from 'vitest';

// 환경 변수 설정 (테스트용)
process.env.OKTA_ISSUER = 'https://test.okta.com/oauth2/default';
process.env.OKTA_AUDIENCE = 'http://localhost:3000';
process.env.SERVER_BASE_URL = 'http://localhost:3000';

// Okta JWT Verifier mock
vi.mock('@okta/jwt-verifier', () => {
  const MockOktaJwtVerifier = class {
    verifyAccessToken(token: string, audience: string) {
      if (token === 'valid-token') {
        return Promise.resolve({
          claims: {
            sub: 'user@example.com',
            aud: audience,
            iss: process.env.OKTA_ISSUER,
            scp: ['mcp:read'],
          },
        });
      }
      if (token === 'expired-token') {
        return Promise.reject(new Error('Jwt is expired'));
      }
      return Promise.reject(new Error('Invalid token'));
    }
  };

  return { default: MockOktaJwtVerifier };
});
