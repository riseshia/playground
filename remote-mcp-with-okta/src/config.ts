export const config = {
  port: parseInt(process.env.PORT || '3000', 10),

  // AWS Cognito OAuth settings
  cognito: {
    userPoolId: process.env.COGNITO_USER_POOL_ID || '',
    region: process.env.COGNITO_REGION || '',
    clientId: process.env.COGNITO_CLIENT_ID || '',
    get issuer(): string {
      return `https://cognito-idp.${this.region}.amazonaws.com/${this.userPoolId}`;
    },
    get openIdConfigUrl(): string {
      return `${this.issuer}/.well-known/openid-configuration`;
    },
  },

  // Server settings
  server: {
    baseUrl: process.env.SERVER_BASE_URL || 'http://localhost:3000',
  },
};

export function validateConfig(): void {
  if (!config.cognito.userPoolId) {
    throw new Error('COGNITO_USER_POOL_ID environment variable is required');
  }
  if (!config.cognito.region) {
    throw new Error('COGNITO_REGION environment variable is required');
  }
  if (!config.cognito.clientId) {
    throw new Error('COGNITO_CLIENT_ID environment variable is required');
  }
}
