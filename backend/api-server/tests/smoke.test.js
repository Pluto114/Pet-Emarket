const assert = require('assert');
const { createApp } = require('../src/app');

async function main() {
  const server = createApp();
  await new Promise((resolve) => server.listen(0, resolve));
  const { port } = server.address();
  const baseUrl = `http://127.0.0.1:${port}`;

  try {
    const health = await request(baseUrl, 'GET', '/api/v1/health');
    assert.strictEqual(health.status, 200);
    assert.strictEqual(health.body.success, true);

    const login = await request(baseUrl, 'POST', '/api/v1/auth/login', {
      username: 'admin',
      password: 'Admin@123456',
    });
    assert.strictEqual(login.status, 200);
    const token = login.body.data.token;
    assert.ok(token);

    const users = await request(baseUrl, 'GET', '/api/v1/users', null, token);
    assert.strictEqual(users.status, 200);
    assert.ok(users.body.data.items.length >= 2);

    const createdProduct = await request(
      baseUrl,
      'POST',
      '/api/v1/products',
      {
        name: 'Smoke Test Toy',
        type: 'GOODS',
        category: 'Toy',
        price: 39,
        stock: 10,
        status: 'ON_SALE',
      },
      token,
    );
    assert.strictEqual(createdProduct.status, 200);
    assert.strictEqual(createdProduct.body.data.product.name, 'Smoke Test Toy');

    const publicProducts = await request(baseUrl, 'GET', '/api/v1/products');
    assert.strictEqual(publicProducts.status, 200);
    assert.ok(publicProducts.body.data.items.length >= 3);
    const productId = publicProducts.body.data.items[0].id;

    const cart = await request(
      baseUrl,
      'POST',
      '/api/v1/cart/items',
      {
        productId,
        quantity: 1,
      },
      token,
    );
    assert.strictEqual(cart.status, 200);
    assert.strictEqual(cart.body.data.item.productId, productId);

    const orderCreated = await request(
      baseUrl,
      'POST',
      '/api/v1/orders',
      {
        addressSnapshot: {
          receiver: 'Smoke Tester',
          phone: '18800000008',
          detail: 'Smoke test address',
        },
      },
      token,
    );
    assert.strictEqual(orderCreated.status, 200);
    assert.strictEqual(orderCreated.body.data.order.status, 0);
    const orderId = orderCreated.body.data.order.id;

    const paid = await request(baseUrl, 'PUT', `/api/v1/orders/${orderId}/pay`, {}, token);
    assert.strictEqual(paid.status, 200);
    assert.strictEqual(paid.body.data.order.status, 1);

    const shipped = await request(baseUrl, 'PUT', `/api/v1/orders/${orderId}/ship`, {}, token);
    assert.strictEqual(shipped.status, 200);
    assert.strictEqual(shipped.body.data.order.status, 2);

    const received = await request(baseUrl, 'PUT', `/api/v1/orders/${orderId}/receive`, {}, token);
    assert.strictEqual(received.status, 200);
    assert.strictEqual(received.body.data.order.status, 3);

    const reviewed = await request(
      baseUrl,
      'PUT',
      `/api/v1/orders/${orderId}/review`,
      { rating: 5, content: 'Good smoke test product.' },
      token,
    );
    assert.strictEqual(reviewed.status, 200);
    assert.strictEqual(reviewed.body.data.order.status, 4);

    const blocked = await request(baseUrl, 'POST', '/api/v1/products', {
      name: 'Blocked Product',
    });
    assert.strictEqual(blocked.status, 401);

    console.log('Smoke tests passed.');
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

function request(baseUrl, method, path, body, token) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, baseUrl);
    const payload = body ? JSON.stringify(body) : null;
    const req = require('http').request(
      {
        hostname: url.hostname,
        port: url.port,
        path: `${url.pathname}${url.search}`,
        method,
        headers: {
          ...(payload ? { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) } : {}),
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
      },
      (res) => {
        let raw = '';
        res.on('data', (chunk) => {
          raw += chunk;
        });
        res.on('end', () => {
          resolve({ status: res.statusCode, body: raw ? JSON.parse(raw) : null });
        });
      },
    );
    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
