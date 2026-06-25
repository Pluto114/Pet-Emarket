const config = {
  port: Number(process.env.PORT || 8080),
  tokenSecret: process.env.PET_EMARKET_TOKEN_SECRET || 'pet-emarket-dev-secret',
  tokenExpiresInSeconds: Number(process.env.PET_EMARKET_TOKEN_TTL || 60 * 60 * 8),
};

module.exports = { config };
