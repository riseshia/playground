import { Request, Response } from 'express';
import { config } from '../config.js';

interface ProtectedResourceMetadata {
  resource: string;
  authorization_servers: string[];
  scopes_supported: string[];
  bearer_methods_supported: string[];
}

export function protectedResourceHandler(_req: Request, res: Response): void {
  const metadata: ProtectedResourceMetadata = {
    resource: config.server.baseUrl,
    authorization_servers: [config.okta.issuer],
    scopes_supported: ['mcp:read'],
    bearer_methods_supported: ['header'],
  };

  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Cache-Control', 'public, max-age=3600');
  res.json(metadata);
}
