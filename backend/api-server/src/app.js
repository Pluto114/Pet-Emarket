const http = require('http');
const { URL } = require('url');
const { createInMemoryStore } = require('./repositories/inMemoryStore');
const { getCurrentUser, hasAnyRole } = require('./middleware/auth');
const { fail, ok, parseJsonBody, sendJson } = require('./utils/http');
const { signToken } = require('./utils/token');

function createApp(dependencies = {}) {
  const store = dependencies.store || createInMemoryStore();

  return http.createServer(async (req, res) => {
    try {
      setCorsHeaders(res);
      if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
      }

      const url = new URL(req.url, 'http://localhost');
      const path = normalizePath(url.pathname);
      const segments = path.split('/').filter(Boolean);
      const body = ['POST', 'PUT', 'PATCH'].includes(req.method) ? await parseJsonBody(req) : {};

      if (path === '/api/v1/health' || path === '/health') {
        ok(res, { status: 'UP', service: 'pet-emarket-api-server' });
        return;
      }

      if (path === '/api/v1/auth/login' && req.method === 'POST') {
        const user = store.findRawUserByUsername(body.username);
        if (!user || !store.verifyPassword(user, body.password || '')) {
          fail(res, 401, '100001', 'Invalid username or password');
          return;
        }
        const token = signToken({ sub: user.id, username: user.username, role: user.role });
        ok(res, { token, user: store.findUserById(user.id) }, 'login success');
        return;
      }

      if (path === '/api/v1/auth/register' && req.method === 'POST') {
        const user = store.createUser({
          username: body.username,
          password: body.password,
          displayName: body.displayName,
          phone: body.phone,
          email: body.email,
          role: 'CUSTOMER',
          memberLevel: 'NORMAL',
        });
        const token = signToken({ sub: user.id, username: user.username, role: user.role });
        ok(res, { token, user }, 'register success');
        return;
      }

      const currentUser = getAuthenticatedUser(req, res, store, path);
      if (currentUser === false) {
        return;
      }

      if (path === '/api/v1/auth/me' && req.method === 'GET') {
        ok(res, { user: store.findUserById(currentUser.id) });
        return;
      }

      if (segments[0] === 'api' && segments[1] === 'v1' && segments[2] === 'users') {
        await handleUsers(req, res, store, currentUser, segments, body);
        return;
      }

      if (segments[0] === 'api' && segments[1] === 'v1' && segments[2] === 'products') {
        await handleProducts(req, res, store, currentUser, segments, body, url);
        return;
      }

      if (segments[0] === 'api' && segments[1] === 'v1' && segments[2] === 'cart' && segments[3] === 'items') {
        await handleCart(req, res, store, currentUser, segments, body);
        return;
      }

      if (segments[0] === 'api' && segments[1] === 'v1' && segments[2] === 'orders') {
        await handleOrders(req, res, store, currentUser, segments, body);
        return;
      }

      fail(res, 404, '500404', 'API not found');
    } catch (error) {
      fail(res, 500, '500000', error.message || 'Internal server error');
    }
  });
}

function getAuthenticatedUser(req, res, store, path) {
  const publicPaths = [
    '/api/v1/health',
    '/health',
    '/api/v1/auth/login',
    '/api/v1/auth/register',
  ];
  const publicProductRead =
    req.method === 'GET' && (path === '/api/v1/products' || /^\/api\/v1\/products\/[^/]+$/.test(path));
  if (publicPaths.includes(path) || publicProductRead) {
    return null;
  }

  try {
    const user = getCurrentUser(req, store);
    if (!user) {
      fail(res, 401, '100002', 'Authentication required');
      return false;
    }
    return user;
  } catch (error) {
    fail(res, 401, '100003', error.message);
    return false;
  }
}

async function handleUsers(req, res, store, currentUser, segments, body) {
  const userId = segments[3];

  if (!userId && req.method === 'GET') {
    if (!requireRoles(res, currentUser, ['ADMIN'])) return;
    ok(res, { items: store.listUsers() });
    return;
  }

  if (!userId && req.method === 'POST') {
    if (!requireRoles(res, currentUser, ['ADMIN'])) return;
    const user = store.createUser(body);
    ok(res, { user }, 'user created');
    return;
  }

  if (userId && req.method === 'GET') {
    if (!canAccessUser(currentUser, userId)) {
      fail(res, 403, '100403', 'No permission to access this user');
      return;
    }
    const user = store.findUserById(userId);
    if (!user) {
      fail(res, 404, '100404', 'User not found');
      return;
    }
    ok(res, { user });
    return;
  }

  if (userId && req.method === 'PUT') {
    if (!canAccessUser(currentUser, userId)) {
      fail(res, 403, '100403', 'No permission to update this user');
      return;
    }
    const patch = { ...body };
    if (currentUser.role !== 'ADMIN') {
      delete patch.role;
      delete patch.status;
      delete patch.memberLevel;
    }
    const user = store.updateUser(userId, patch);
    if (!user) {
      fail(res, 404, '100404', 'User not found');
      return;
    }
    ok(res, { user }, 'user updated');
    return;
  }

  if (userId && req.method === 'DELETE') {
    if (!requireRoles(res, currentUser, ['ADMIN'])) return;
    const deleted = store.deleteUser(userId);
    if (!deleted) {
      fail(res, 404, '100404', 'User not found');
      return;
    }
    ok(res, { deleted: true }, 'user deleted');
    return;
  }

  fail(res, 405, '500405', 'Method not allowed');
}

async function handleProducts(req, res, store, currentUser, segments, body, url) {
  const productId = segments[3];

  if (!productId && req.method === 'GET') {
    ok(res, {
      items: store.listProducts({
        keyword: url.searchParams.get('keyword'),
        type: url.searchParams.get('type'),
      }),
    });
    return;
  }

  if (!productId && req.method === 'POST') {
    if (!requireRoles(res, currentUser, ['ADMIN', 'MERCHANT'])) return;
    const product = store.createProduct(body);
    ok(res, { product }, 'product created');
    return;
  }

  if (productId && req.method === 'GET') {
    const product = store.findProductById(productId);
    if (!product) {
      fail(res, 404, '200404', 'Product not found');
      return;
    }
    ok(res, { product });
    return;
  }

  if (productId && req.method === 'PUT') {
    if (!requireRoles(res, currentUser, ['ADMIN', 'MERCHANT'])) return;
    const product = store.updateProduct(productId, body);
    if (!product) {
      fail(res, 404, '200404', 'Product not found');
      return;
    }
    ok(res, { product }, 'product updated');
    return;
  }

  if (productId && req.method === 'DELETE') {
    if (!requireRoles(res, currentUser, ['ADMIN', 'MERCHANT'])) return;
    const deleted = store.deleteProduct(productId);
    if (!deleted) {
      fail(res, 404, '200404', 'Product not found');
      return;
    }
    ok(res, { deleted: true }, 'product deleted');
    return;
  }

  fail(res, 405, '500405', 'Method not allowed');
}

async function handleCart(req, res, store, currentUser, segments, body) {
  const itemId = segments[4];

  if (!itemId && req.method === 'GET') {
    ok(res, { items: store.listCartItems(currentUser.id) });
    return;
  }

  if (!itemId && req.method === 'POST') {
    const item = store.addCartItem(currentUser.id, body);
    ok(res, { item }, 'cart item added');
    return;
  }

  if (itemId && req.method === 'PUT') {
    const item = store.updateCartItem(currentUser.id, itemId, body);
    if (!item) {
      fail(res, 404, '300404', 'Cart item not found');
      return;
    }
    ok(res, { item }, 'cart item updated');
    return;
  }

  if (itemId && req.method === 'DELETE') {
    const deleted = store.deleteCartItem(currentUser.id, itemId);
    if (!deleted) {
      fail(res, 404, '300404', 'Cart item not found');
      return;
    }
    ok(res, { deleted: true }, 'cart item deleted');
    return;
  }

  fail(res, 405, '500405', 'Method not allowed');
}

async function handleOrders(req, res, store, currentUser, segments, body) {
  const orderId = segments[3];
  const action = segments[4];

  if (!orderId && req.method === 'GET') {
    ok(res, { items: store.listOrders(currentUser) });
    return;
  }

  if (!orderId && req.method === 'POST') {
    const order = store.createOrderFromCart(currentUser.id, body);
    ok(res, { order }, 'order created');
    return;
  }

  if (orderId && !action && req.method === 'GET') {
    const order = store.findOrderById(orderId);
    if (!order) {
      fail(res, 404, '300404', 'Order not found');
      return;
    }
    if (!canAccessOrder(currentUser, order)) {
      fail(res, 403, '100403', 'No permission to access this order');
      return;
    }
    ok(res, { order });
    return;
  }

  const actionMap = {
    pay: 'pay',
    ship: 'ship',
    receive: 'receive',
    review: 'review',
    cancel: 'cancel',
    'apply-refund': 'applyRefund',
    'audit-refund': 'auditRefund',
    'admin-refund': 'adminRefund',
  };
  if (orderId && actionMap[action] && ['POST', 'PUT'].includes(req.method)) {
    const order = store.findOrderById(orderId);
    if (!order) {
      fail(res, 404, '300404', 'Order not found');
      return;
    }
    if (!canOperateOrder(currentUser, order, actionMap[action])) {
      fail(res, 403, '100403', 'No permission to operate this order');
      return;
    }
    const updated = store.transitionOrder(orderId, actionMap[action], currentUser, body);
    ok(res, { order: updated }, 'order updated');
    return;
  }

  fail(res, 405, '500405', 'Method not allowed');
}

function canAccessUser(currentUser, userId) {
  return currentUser && (currentUser.role === 'ADMIN' || currentUser.id === userId);
}

function canAccessOrder(currentUser, order) {
  return currentUser && (currentUser.role === 'ADMIN' || currentUser.role === 'MERCHANT' || order.userId === currentUser.id);
}

function canOperateOrder(currentUser, order, action) {
  if (!currentUser) return false;
  const adminActions = ['ship', 'auditRefund', 'adminRefund'];
  if (adminActions.includes(action)) {
    return currentUser.role === 'ADMIN' || currentUser.role === 'MERCHANT';
  }
  return currentUser.role === 'ADMIN' || order.userId === currentUser.id;
}

function requireRoles(res, currentUser, roles) {
  if (!hasAnyRole(currentUser, roles)) {
    fail(res, 403, '100403', 'Forbidden');
    return false;
  }
  return true;
}

function normalizePath(pathname) {
  return pathname.replace(/\/+$/, '') || '/';
}

function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,PATCH,DELETE,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization,X-Trace-Id');
}

module.exports = { createApp };
