const { readBearerToken } = require('../utils/http');
const { verifyToken } = require('../utils/token');

function getCurrentUser(req, store) {
  const token = readBearerToken(req);
  if (!token) {
    return null;
  }
  const payload = verifyToken(token);
  const user = store.findRawUserById(payload.sub);
  if (!user || user.status !== 'ACTIVE') {
    return null;
  }
  return user;
}

function hasAnyRole(user, roles) {
  return Boolean(user && roles.includes(user.role));
}

module.exports = { getCurrentUser, hasAnyRole };
