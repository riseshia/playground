import { Request, Response } from 'express';
import { config } from '../config.js';

// Cognito OpenID Configuration のキャッシュ
let metadataCache: Record<string, unknown> | null = null;
let cacheTime: number | null = null;
const CACHE_DURATION = 3600000; // 1 hour

async function fetchCognitoMetadata(): Promise<Record<string, unknown>> {
  const now = Date.now();

  if (metadataCache && cacheTime && (now - cacheTime < CACHE_DURATION)) {
    return metadataCache;
  }

  console.log(`Fetching Cognito metadata from: ${config.cognito.openIdConfigUrl}`);
  const response = await fetch(config.cognito.openIdConfigUrl);
  if (!response.ok) {
    throw new Error(`Failed to fetch Cognito metadata: ${response.status}`);
  }
  metadataCache = await response.json() as Record<string, unknown>;
  cacheTime = now;
  return metadataCache;
}

// AS メタデータプロキシ
// issuer を自サーバーに上書きし、authorization/token エンドポイントも自サーバー経由にする
export async function authorizationServerHandler(_req: Request, res: Response): Promise<void> {
  try {
    const cognitoMetadata = await fetchCognitoMetadata();
    const metadata = { ...cognitoMetadata };

    // issuer を自サーバーに上書き（Claude Code が issuer 一致を検証するため）
    metadata.issuer = config.server.baseUrl;

    // authorize/token エンドポイントを自サーバー経由にする
    metadata.authorization_endpoint = `${config.server.baseUrl}/authorize`;
    metadata.token_endpoint = `${config.server.baseUrl}/token`;

    // Cognito は PKCE サポートをメタデータに含めないので追加
    if (!metadata.code_challenge_methods_supported) {
      metadata.code_challenge_methods_supported = ['S256'];
    }

    // scopes_supported を Cognito クライアントが対応するものに制限
    metadata.scopes_supported = ['openid', 'email'];

    res.json(metadata);
  } catch (error) {
    console.error('Error proxying authorization server metadata:', error);
    res.status(500).json({
      error: 'server_error',
      error_description: 'Unable to retrieve authorization server metadata',
    });
  }
}

// /authorize → Cognito の authorization_endpoint にリダイレクト
export async function authorizeHandler(req: Request, res: Response): Promise<void> {
  try {
    const cognitoMetadata = await fetchCognitoMetadata();
    const authEndpoint = cognitoMetadata.authorization_endpoint as string;
    if (!authEndpoint) {
      throw new Error('authorization_endpoint not found in Cognito metadata');
    }

    // Cognito クライアントが対応するスコープのみに制限
    const ALLOWED_SCOPES = new Set(['openid', 'email']);

    const url = new URL(authEndpoint);
    for (const [key, value] of Object.entries(req.query)) {
      if (typeof value === 'string') {
        if (key === 'scope') {
          // スコープをフィルタリング
          const filtered = value.split(' ').filter(s => ALLOWED_SCOPES.has(s)).join(' ');
          url.searchParams.set(key, filtered || 'openid');
        } else if (key === 'resource') {
          // Cognito は RFC 8707 resource パラメータをサポートしないので除去
          continue;
        } else {
          url.searchParams.set(key, value);
        }
      }
    }

    console.log(`Redirecting to Cognito authorize: ${url.toString()}`);
    res.redirect(url.toString());
  } catch (error) {
    console.error('Error redirecting to authorize:', error);
    res.status(500).json({
      error: 'server_error',
      error_description: 'Unable to redirect to authorization endpoint',
    });
  }
}

// /token → Cognito の token_endpoint にプロキシ
export async function tokenHandler(req: Request, res: Response): Promise<void> {
  try {
    const cognitoMetadata = await fetchCognitoMetadata();
    const tokenEndpoint = cognitoMetadata.token_endpoint as string;
    if (!tokenEndpoint) {
      throw new Error('token_endpoint not found in Cognito metadata');
    }

    console.log(`Proxying token request to Cognito: ${tokenEndpoint}`);

    // Cognito が対応しないパラメータを除去してボディを構築
    const params = new URLSearchParams(req.body as Record<string, string>);
    // Cognito は RFC 8707 の resource パラメータをサポートしないので除去
    params.delete('resource');
    const body = params.toString();

    console.log(`Token request body: ${body}`);

    const tokenResponse = await fetch(tokenEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body,
    });

    const responseBody = await tokenResponse.text();
    console.log(`Token response status: ${tokenResponse.status}`);
    console.log(`Token response body: ${responseBody.substring(0, 500)}`);

    // レスポンスヘッダーとステータスをそのまま返す
    res.status(tokenResponse.status)
      .set('Content-Type', tokenResponse.headers.get('content-type') || 'application/json')
      .send(responseBody);
  } catch (error) {
    console.error('Error proxying token request:', error);
    res.status(500).json({
      error: 'server_error',
      error_description: 'Unable to proxy token request',
    });
  }
}
