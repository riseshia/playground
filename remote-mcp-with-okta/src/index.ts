import { createApp } from './app.js';
import { config, validateConfig } from './config.js';

async function main(): Promise<void> {
  // 환경 변수 검증
  validateConfig();

  const app = createApp();

  // 서버 시작
  app.listen(config.port, () => {
    console.log(`MCP Server running at http://localhost:${config.port}`);
    console.log(`Health check: http://localhost:${config.port}/health`);
    console.log(`OAuth metadata: http://localhost:${config.port}/.well-known/oauth-protected-resource`);
    console.log(`MCP endpoint: http://localhost:${config.port}/mcp`);
  });
}

main().catch(console.error);
