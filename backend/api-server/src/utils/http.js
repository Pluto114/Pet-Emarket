function sendJson(res, status, payload) {
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Trace-Id',
  });
  res.end(JSON.stringify(payload));
}

function ok(res, data = null, message = 'success') {
  sendJson(res, 200, {
    success: true,
    code: '000000',
    message,
    data,
    traceId: newTraceId(),
    timestamp: Date.now(),
  });
}

function fail(res, status, code, message, errors = []) {
  sendJson(res, status, {
    success: false,
    code,
    message,
    data: null,
    errors,
    traceId: newTraceId(),
    timestamp: Date.now(),
  });
}

function parseJsonBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (chunk) => {
      raw += chunk;
      if (raw.length > 1024 * 1024) {
        reject(new Error('Request body too large'));
        req.destroy();
      }
    });
    req.on('end', () => {
      if (!raw.trim()) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(raw));
      } catch (error) {
        reject(new Error('Invalid JSON body'));
      }
    });
    req.on('error', reject);
  });
}

function newTraceId() {
  return `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 10)}`;
}

function readBearerToken(req) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) {
    return null;
  }
  return header.slice('Bearer '.length).trim();
}

module.exports = {
  fail,
  ok,
  parseJsonBody,
  readBearerToken,
  sendJson,
};
