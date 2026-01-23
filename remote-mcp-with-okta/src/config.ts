export const config = {
  port: parseInt(process.env.PORT || '3000', 10),

  // Okta OAuth settings
  okta: {
    issuer: process.env.OKTA_ISSUER || '',
    audience: process.env.OKTA_AUDIENCE || '',
  },

  // Server settings
  server: {
    baseUrl: process.env.SERVER_BASE_URL || 'http://localhost:3000',
  },
};

export function validateConfig(): void {
  if (!config.okta.issuer) {
    throw new Error('OKTA_ISSUER environment variable is required');
  }
  if (!config.okta.audience) {
    throw new Error('OKTA_AUDIENCE environment variable is required');
  }
}
