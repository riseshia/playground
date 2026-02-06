import { Request, Response } from 'express';
import { config } from '../config.js';

// リファレンス実装に合わせ、authorization_servers に AS メタデータプロキシの URL を設定
export function protectedResourceHandler(_req: Request, res: Response): void {
  const metadata = {
    resource: config.server.baseUrl,
    authorization_servers: [
      config.server.baseUrl,
    ],
    bearer_methods_supported: ['header'],
    scopes_supported: ['openid', 'email'],
  };

  res.json(metadata);
}
