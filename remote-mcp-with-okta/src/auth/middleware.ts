import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import jwkToPem from 'jwk-to-pem';
import { config } from '../config.js';

// JWKS と AS メタデータのキャッシュ
let jwksCache: { keys: Array<{ kid: string; [key: string]: unknown }> } | null = null;
let jwksCacheTime: number | null = null;
let authServerMetadataCache: Record<string, unknown> | null = null;
let authServerMetadataCacheTime: number | null = null;
const CACHE_DURATION = 3600000; // 1 hour

async function getAuthServerMetadata(): Promise<Record<string, unknown>> {
  const now = Date.now();
  if (authServerMetadataCache && authServerMetadataCacheTime &&
      (now - authServerMetadataCacheTime < CACHE_DURATION)) {
    return authServerMetadataCache;
  }

  const response = await fetch(config.cognito.openIdConfigUrl);
  if (!response.ok) {
    throw new Error('Unable to fetch authorization server metadata');
  }
  authServerMetadataCache = await response.json() as Record<string, unknown>;
  authServerMetadataCacheTime = now;
  return authServerMetadataCache;
}

async function getJwks(): Promise<{ keys: Array<{ kid: string; [key: string]: unknown }> }> {
  const now = Date.now();
  if (jwksCache && jwksCacheTime && (now - jwksCacheTime < CACHE_DURATION)) {
    return jwksCache;
  }

  const metadata = await getAuthServerMetadata();
  const jwksUri = metadata.jwks_uri as string;
  if (!jwksUri) {
    throw new Error('jwks_uri not found in authorization server metadata');
  }

  const response = await fetch(jwksUri);
  if (!response.ok) {
    throw new Error('Unable to fetch JWKs');
  }
  jwksCache = await response.json() as { keys: Array<{ kid: string; [key: string]: unknown }> };
  jwksCacheTime = now;
  return jwksCache;
}

async function validateToken(token: string): Promise<Record<string, unknown>> {
  // kid を取得するためにデコード（検証なし）
  const decoded = jwt.decode(token, { complete: true });
  if (!decoded) {
    throw new Error('Invalid token format');
  }

  const { kid } = decoded.header;

  // JWKS から対応する鍵を取得
  const jwks = await getJwks();
  const key = jwks.keys.find(k => k.kid === kid);
  if (!key) {
    throw new Error('Invalid token - key not found');
  }

  // JWK を PEM に変換
  const pem = jwkToPem(key as unknown as jwkToPem.JWK);

  // issuer を AS メタデータから取得
  const metadata = await getAuthServerMetadata();
  const expectedIssuer = metadata.issuer as string;
  if (!expectedIssuer) {
    throw new Error('issuer not found in authorization server metadata');
  }

  // トークンを検証（リファレンスに合わせ audience チェックなし）
  const verified = jwt.verify(token, pem, {
    issuer: expectedIssuer,
    algorithms: ['RS256'],
  }) as Record<string, unknown>;

  return verified;
}

// Express Request に user 属性追加
declare global {
  namespace Express {
    interface Request {
      user?: Record<string, unknown>;
    }
  }
}

export async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    console.log(`[AUTH] No bearer token. Auth header: ${authHeader || '(none)'}`);
    res.status(401).set({
      'WWW-Authenticate': `Bearer resource_metadata="${config.server.baseUrl}/.well-known/oauth-protected-resource"`,
    }).json({
      error: 'unauthorized',
      error_description: 'Valid bearer token required',
    });
    return;
  }

  const token = authHeader.split(' ')[1];
  console.log(`[AUTH] Validating token: ${token.substring(0, 20)}...`);

  try {
    const decodedToken = await validateToken(token);
    console.log(`[AUTH] Token valid. Claims: ${JSON.stringify(Object.keys(decodedToken))}`);
    req.user = decodedToken;
    next();
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Token verification failed';
    console.error('Token validation failed:', message);
    res.status(401).set({
      'WWW-Authenticate': `Bearer resource_metadata="${config.server.baseUrl}/.well-known/oauth-protected-resource", error="invalid_token", error_description="${message}"`,
    }).json({
      error: 'unauthorized',
      error_description: message,
    });
  }
}
