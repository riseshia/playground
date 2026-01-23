import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';

export function createMcpServer(): McpServer {
  const server = new McpServer({
    name: 'remote-mcp-okta',
    version: '1.0.0',
  });

  // ping 도구 정의
  server.tool(
    'ping',
    'A simple ping tool that returns pong with your message',
    {
      message: z.string().optional().describe('Optional message to include in the response'),
    },
    async ({ message }) => {
      const responseMessage = message ? `pong: ${message}` : 'pong: hello';
      return {
        content: [
          {
            type: 'text',
            text: responseMessage,
          },
        ],
      };
    }
  );

  return server;
}
