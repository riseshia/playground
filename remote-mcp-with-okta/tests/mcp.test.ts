import { describe, it, expect } from 'vitest';
import request from 'supertest';
import './setup.js';
import { createApp } from '../src/app.js';

describe('MCP Endpoint', () => {
  const app = createApp();

  describe('POST /mcp - Authentication', () => {
    it('should return 401 without authorization header', async () => {
      const response = await request(app)
        .post('/mcp')
        .send({ jsonrpc: '2.0', id: 1, method: 'tools/list' });

      expect(response.status).toBe(401);
      expect(response.headers['www-authenticate']).toBe(
        'Bearer resource="http://localhost:3000"'
      );
      expect(response.body.error.code).toBe(-32001);
    });

    it('should return 401 with invalid token', async () => {
      const response = await request(app)
        .post('/mcp')
        .set('Authorization', 'Bearer invalid-token')
        .send({ jsonrpc: '2.0', id: 1, method: 'tools/list' });

      expect(response.status).toBe(401);
      expect(response.headers['www-authenticate']).toBe(
        'Bearer resource="http://localhost:3000", error="invalid_token", error_description="The access token is invalid"'
      );
    });

    it('should return 401 with expired token', async () => {
      const response = await request(app)
        .post('/mcp')
        .set('Authorization', 'Bearer expired-token')
        .send({ jsonrpc: '2.0', id: 1, method: 'tools/list' });

      expect(response.status).toBe(401);
      expect(response.headers['www-authenticate']).toBe(
        'Bearer resource="http://localhost:3000", error="invalid_token", error_description="The access token has expired"'
      );
    });
  });

  describe('POST /mcp - MCP Operations', () => {
    const mcpHeaders = {
      'Authorization': 'Bearer valid-token',
      'Accept': 'application/json, text/event-stream',
      'Content-Type': 'application/json',
    };

    // SSE 응답에서 JSON 데이터 추출하는 헬퍼 함수
    function parseSSEResponse(text: string): unknown[] {
      const results: unknown[] = [];
      const lines = text.split('\n');
      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const jsonStr = line.slice(6);
          if (jsonStr.trim()) {
            results.push(JSON.parse(jsonStr));
          }
        }
      }
      return results;
    }

    it('should return tools list with valid token', async () => {
      const response = await request(app)
        .post('/mcp')
        .set(mcpHeaders)
        .send({ jsonrpc: '2.0', id: 1, method: 'tools/list' });

      expect(response.status).toBe(200);

      const messages = parseSSEResponse(response.text);
      const toolsResponse = messages.find(
        (m: any) => m.id === 1 && m.result?.tools
      ) as any;

      expect(toolsResponse).toBeDefined();
      expect(toolsResponse.jsonrpc).toBe('2.0');
      expect(toolsResponse.result.tools).toContainEqual(
        expect.objectContaining({ name: 'ping' })
      );
    });

    it('should call ping tool successfully', async () => {
      const response = await request(app)
        .post('/mcp')
        .set(mcpHeaders)
        .send({
          jsonrpc: '2.0',
          id: 1,
          method: 'tools/call',
          params: {
            name: 'ping',
            arguments: { message: 'hello world' },
          },
        });

      expect(response.status).toBe(200);

      const messages = parseSSEResponse(response.text);
      const pingResponse = messages.find(
        (m: any) => m.id === 1 && m.result?.content
      ) as any;

      expect(pingResponse).toBeDefined();
      expect(pingResponse.result.content[0].text).toBe('pong: hello world');
    });

    it('should call ping tool with default message', async () => {
      const response = await request(app)
        .post('/mcp')
        .set(mcpHeaders)
        .send({
          jsonrpc: '2.0',
          id: 1,
          method: 'tools/call',
          params: {
            name: 'ping',
            arguments: {},
          },
        });

      expect(response.status).toBe(200);

      const messages = parseSSEResponse(response.text);
      const pingResponse = messages.find(
        (m: any) => m.id === 1 && m.result?.content
      ) as any;

      expect(pingResponse).toBeDefined();
      expect(pingResponse.result.content[0].text).toBe('pong: hello');
    });
  });

  describe('GET /mcp', () => {
    it('should return 405 Method Not Allowed', async () => {
      const response = await request(app).get('/mcp');

      expect(response.status).toBe(405);
      expect(response.body.error.code).toBe(-32000);
      expect(response.body.error.message).toContain('stateless');
    });
  });

  describe('DELETE /mcp', () => {
    it('should return 405 Method Not Allowed', async () => {
      const response = await request(app).delete('/mcp');

      expect(response.status).toBe(405);
      expect(response.body.error.code).toBe(-32000);
    });
  });
});
