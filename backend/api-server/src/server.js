const { createApp } = require('./app');
const { config } = require('./config');

const server = createApp();

server.listen(config.port, () => {
  console.log(`Pet-Emarket API server listening on http://localhost:${config.port}`);
});
