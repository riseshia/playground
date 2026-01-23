import { describe, it, expect } from 'vitest';
import request from 'supertest';
import './setup.js';
import { createApp } from '../src/app.js';

describe('GET /.well-known/oauth-protected-resource', () => {
  const app = createApp();

  it('should return OAuth protected resource metadata', async () => {
    const response = await request(app).get('/.well-known/oauth-protected-resource');

    expect(response.status).toBe(200);
    expect(response.headers['content-type']).toMatch(/application\/json/);
    expect(response.headers['cache-control']).toBe('public, max-age=3600');

    expect(response.body).toEqual({
      resource: 'http://localhost:3000',
      authorization_servers: ['https://test.okta.com/oauth2/default'],
      scopes_supported: ['mcp:read'],
      bearer_methods_supported: ['header'],
    });
  });
});
