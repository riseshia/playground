import { Request, Response, NextFunction } from 'express';
import OktaJwtVerifier from '@okta/jwt-verifier';
import { config } from '../config.js';

// Okta JWT 검증기 초기화
const oktaJwtVerifier = new OktaJwtVerifier({
  issuer: config.okta.issuer,
});

// Express Request에 user 속성 추가를 위한 타입 확장
declare global {
  namespace Express {
    interface Request {
      user?: {
        sub: string;
        claims: Record<string, unknown>;
      };
    }
  }
}

function extractBearerToken(authHeader: string | undefined): string | null {
  if (!authHeader) {
    return null;
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0].toLowerCase() !== 'bearer') {
    return null;
  }

  return parts[1];
}

function sendUnauthorized(res: Response, error?: string, errorDescription?: string): void {
  let wwwAuthenticate = `Bearer resource="${config.server.baseUrl}"`;

  if (error) {
    wwwAuthenticate += `, error="${error}"`;
    if (errorDescription) {
      wwwAuthenticate += `, error_description="${errorDescription}"`;
    }
  }

  res.setHeader('WWW-Authenticate', wwwAuthenticate);
  res.status(401).json({
    jsonrpc: '2.0',
    error: {
      code: -32001,
      message: error || 'Unauthorized',
      data: errorDescription,
    },
    id: null,
  });
}

export async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const token = extractBearerToken(req.headers.authorization);

  if (!token) {
    sendUnauthorized(res);
    return;
  }

  try {
    const jwt = await oktaJwtVerifier.verifyAccessToken(token, config.okta.audience);

    // 사용자 정보를 요청 객체에 첨부
    req.user = {
      sub: jwt.claims.sub as string,
      claims: jwt.claims as Record<string, unknown>,
    };

    next();
  } catch (error) {
    console.error('JWT verification failed:', error);

    if (error instanceof Error) {
      if (error.message.includes('expired')) {
        sendUnauthorized(res, 'invalid_token', 'The access token has expired');
      } else if (error.message.includes('audience')) {
        sendUnauthorized(res, 'invalid_token', 'Invalid audience');
      } else {
        sendUnauthorized(res, 'invalid_token', 'The access token is invalid');
      }
    } else {
      sendUnauthorized(res, 'invalid_token', 'Token verification failed');
    }
  }
}
