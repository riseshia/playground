import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { createMcpServer } from './mcp-server.js';
import { authMiddleware } from './auth/middleware.js';
import { protectedResourceHandler } from './auth/protected-resource.js';

export function createApp() {
  const app = express();

  // CORS 설정
  app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Mcp-Session-Id'],
    exposedHeaders: ['Mcp-Session-Id'],
  }));

  // JSON 파싱
  app.use(express.json());

  // ============================================================
  // Routes
  // ============================================================

  // Health check (인증 불필요)
  app.get('/health', (_req: Request, res: Response) => {
    res.json({ status: 'ok' });
  });

  // OAuth Protected Resource 메타데이터 (인증 불필요)
  app.get('/.well-known/oauth-protected-resource', protectedResourceHandler);

  // MCP 엔드포인트 (인증 필요)
  app.post('/mcp', authMiddleware, async (req: Request, res: Response, next: NextFunction) => {
    try {
      // 각 요청마다 새로운 MCP 서버와 Transport 생성 (stateless 모드)
      const server = createMcpServer();
      const transport = new StreamableHTTPServerTransport({
        sessionIdGenerator: undefined, // stateless 모드
      });

      // Transport를 서버에 연결
      await server.connect(transport);

      // 요청 처리
      await transport.handleRequest(req, res, req.body);
    } catch (error) {
      next(error);
    }
  });

  // GET/DELETE 요청 처리 (세션 관리용, stateless이므로 405 반환)
  app.get('/mcp', (_req: Request, res: Response) => {
    res.status(405).json({
      jsonrpc: '2.0',
      error: {
        code: -32000,
        message: 'Method not allowed. This server operates in stateless mode.',
      },
      id: null,
    });
  });

  app.delete('/mcp', (_req: Request, res: Response) => {
    res.status(405).json({
      jsonrpc: '2.0',
      error: {
        code: -32000,
        message: 'Method not allowed. This server operates in stateless mode.',
      },
      id: null,
    });
  });

  // 에러 핸들러
  app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
    console.error('Server error:', err);
    res.status(500).json({
      jsonrpc: '2.0',
      error: {
        code: -32603,
        message: 'Internal server error',
      },
      id: null,
    });
  });

  return app;
}
