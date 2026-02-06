import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { createMcpServer } from './mcp-server.js';
import { authMiddleware } from './auth/middleware.js';
import { protectedResourceHandler } from './auth/protected-resource.js';
import { authorizationServerHandler, authorizeHandler, tokenHandler } from './auth/authorization-server.js';

export function createApp() {
  const app = express();

  // CORS
  app.use(cors());
  app.use(express.json());

  // リクエストログ
  app.use((req: Request, _res: Response, next: NextFunction) => {
    console.log(`${req.method} ${req.path}`);
    next();
  });

  // ============================================================
  // Routes
  // ============================================================

  // Health check
  app.get('/health', (_req: Request, res: Response) => {
    res.json({ status: 'ok' });
  });

  // Protected Resource Metadata (RFC 9728)
  app.get('/.well-known/oauth-protected-resource', protectedResourceHandler);

  // Authorization Server Metadata proxy (Cognito OpenID Configuration をプロキシ)
  app.get('/.well-known/oauth-authorization-server', authorizationServerHandler);

  // OAuth エンドポイントプロキシ (Cognito に転送)
  app.get('/authorize', authorizeHandler);
  app.use('/token', express.urlencoded({ extended: true }));
  app.post('/token', tokenHandler);

  // MCP エンドポイント (認証必要)
  app.post('/mcp', authMiddleware, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const server = createMcpServer();
      const transport = new StreamableHTTPServerTransport({
        sessionIdGenerator: undefined, // stateless
      });

      await server.connect(transport);
      await transport.handleRequest(req, res, req.body);
    } catch (error) {
      next(error);
    }
  });

  // GET/DELETE → 405 (stateless)
  app.get('/mcp', (_req: Request, res: Response) => {
    res.status(405).json({
      jsonrpc: '2.0',
      error: { code: -32000, message: 'Method not allowed. This server operates in stateless mode.' },
      id: null,
    });
  });

  app.delete('/mcp', (_req: Request, res: Response) => {
    res.status(405).json({
      jsonrpc: '2.0',
      error: { code: -32000, message: 'Method not allowed. This server operates in stateless mode.' },
      id: null,
    });
  });

  // エラーハンドラ
  app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
    console.error('Server error:', err);
    res.status(500).json({
      jsonrpc: '2.0',
      error: { code: -32603, message: 'Internal server error' },
      id: null,
    });
  });

  return app;
}
