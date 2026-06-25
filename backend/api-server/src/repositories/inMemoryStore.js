const crypto = require('crypto');

function createInMemoryStore() {
  const store = {
    users: new Map(),
    products: new Map(),
    cartItems: new Map(),
    orders: new Map(),
  };

  const admin = createUserRecord({
    username: 'admin',
    password: 'Admin@123456',
    displayName: 'System Admin',
    phone: '18800000000',
    email: 'admin@pet-emarket.local',
    role: 'ADMIN',
    memberLevel: 'SVIP',
    status: 'ACTIVE',
  });
  const demo = createUserRecord({
    username: 'demo',
    password: 'Demo@123456',
    displayName: 'Demo User',
    phone: '18800000001',
    email: 'demo@pet-emarket.local',
    role: 'CUSTOMER',
    memberLevel: 'VIP',
    status: 'ACTIVE',
  });
  store.users.set(admin.id, admin);
  store.users.set(demo.id, demo);

  [
    {
      name: 'British Shorthair Kitten',
      type: 'PET_LIVE',
      category: 'Cat',
      storeId: 'store-001',
      price: 2680,
      stock: 1,
      status: 'ON_SALE',
      description: 'Vaccinated kitten with quarantine certificate and trace record.',
      tags: ['cat', 'kitten', 'vaccinated'],
      livePet: {
        petCode: 'PET-CAT-0001',
        breed: 'British Shorthair',
        healthStatus: 'Healthy',
        vaccineCertNo: 'VAC-2026-0001',
        quarantineCertNo: 'QUA-2026-0001',
      },
    },
    {
      name: 'Premium Cat Food 2kg',
      type: 'GOODS',
      category: 'Food',
      storeId: 'store-001',
      price: 129,
      stock: 88,
      status: 'ON_SALE',
      description: 'High protein daily food for young cats.',
      tags: ['food', 'cat'],
    },
  ].forEach((product) => {
    const record = createProductRecord(product);
    store.products.set(record.id, record);
  });

  return {
    createUser(input) {
      if (findUserByUsername(store, input.username)) {
        throw new Error('Username already exists');
      }
      const record = createUserRecord(input);
      store.users.set(record.id, record);
      return sanitizeUser(record);
    },
    deleteUser(id) {
      return store.users.delete(id);
    },
    findUserById(id) {
      const user = store.users.get(id);
      return user ? sanitizeUser(user) : null;
    },
    findRawUserById(id) {
      return store.users.get(id) || null;
    },
    findRawUserByUsername(username) {
      return findUserByUsername(store, username);
    },
    listUsers() {
      return [...store.users.values()].map(sanitizeUser);
    },
    updateUser(id, patch) {
      const current = store.users.get(id);
      if (!current) {
        return null;
      }
      const updated = {
        ...current,
        displayName: patch.displayName ?? current.displayName,
        phone: patch.phone ?? current.phone,
        email: patch.email ?? current.email,
        role: patch.role ?? current.role,
        memberLevel: patch.memberLevel ?? current.memberLevel,
        status: patch.status ?? current.status,
        updatedAt: new Date().toISOString(),
      };
      if (patch.password) {
        const passwordState = hashPassword(patch.password);
        updated.passwordHash = passwordState.passwordHash;
        updated.passwordSalt = passwordState.passwordSalt;
      }
      store.users.set(id, updated);
      return sanitizeUser(updated);
    },
    verifyPassword(user, password) {
      const passwordHash = hashPassword(password, user.passwordSalt).passwordHash;
      return crypto.timingSafeEqual(Buffer.from(passwordHash), Buffer.from(user.passwordHash));
    },
    createProduct(input) {
      const record = createProductRecord(input);
      store.products.set(record.id, record);
      return record;
    },
    deleteProduct(id) {
      return store.products.delete(id);
    },
    findProductById(id) {
      return store.products.get(id) || null;
    },
    listProducts(query = {}) {
      return [...store.products.values()].filter((product) => {
        const keyword = String(query.keyword || '').trim().toLowerCase();
        const type = String(query.type || '').trim();
        if (keyword && !`${product.name} ${product.category} ${product.description}`.toLowerCase().includes(keyword)) {
          return false;
        }
        if (type && product.type !== type) {
          return false;
        }
        return true;
      });
    },
    updateProduct(id, patch) {
      const current = store.products.get(id);
      if (!current) {
        return null;
      }
      const updated = {
        ...current,
        ...patch,
        id: current.id,
        updatedAt: new Date().toISOString(),
      };
      store.products.set(id, updated);
      return updated;
    },
    listCartItems(userId) {
      return [...store.cartItems.values()]
        .filter((item) => item.userId === userId)
        .map((item) => hydrateCartItem(store, item))
        .filter(Boolean);
    },
    addCartItem(userId, input) {
      const product = store.products.get(input.productId);
      if (!product || product.status !== 'ON_SALE') {
        throw new Error('Product is not available');
      }
      const quantity = Math.max(1, Number(input.quantity || 1));
      if (product.stock < quantity) {
        throw new Error('Insufficient stock');
      }
      const existing = [...store.cartItems.values()].find((item) => item.userId === userId && item.productId === product.id);
      if (existing) {
        existing.quantity += quantity;
        existing.updatedAt = new Date().toISOString();
        return hydrateCartItem(store, existing);
      }
      const now = new Date().toISOString();
      const item = {
        id: newId('cart'),
        userId,
        productId: product.id,
        quantity,
        createdAt: now,
        updatedAt: now,
      };
      store.cartItems.set(item.id, item);
      return hydrateCartItem(store, item);
    },
    updateCartItem(userId, itemId, patch) {
      const item = store.cartItems.get(itemId);
      if (!item || item.userId !== userId) {
        return null;
      }
      const product = store.products.get(item.productId);
      const quantity = Math.max(1, Number(patch.quantity || item.quantity));
      if (!product || product.stock < quantity) {
        throw new Error('Insufficient stock');
      }
      item.quantity = quantity;
      item.updatedAt = new Date().toISOString();
      return hydrateCartItem(store, item);
    },
    deleteCartItem(userId, itemId) {
      const item = store.cartItems.get(itemId);
      if (!item || item.userId !== userId) {
        return false;
      }
      return store.cartItems.delete(itemId);
    },
    createOrderFromCart(userId, input = {}) {
      const requestedIds = Array.isArray(input.cartItemIds) ? input.cartItemIds : [];
      const cartItems = [...store.cartItems.values()].filter((item) => {
        if (item.userId !== userId) return false;
        return requestedIds.length === 0 || requestedIds.includes(item.id);
      });
      if (cartItems.length === 0) {
        throw new Error('Cart is empty');
      }

      const orderItems = cartItems.map((item) => {
        const product = store.products.get(item.productId);
        if (!product || product.status !== 'ON_SALE') {
          throw new Error(`Product ${item.productId} is not available`);
        }
        if (product.stock < item.quantity) {
          throw new Error(`Insufficient stock for ${product.name}`);
        }
        return {
          id: newId('oi'),
          productId: product.id,
          productName: product.name,
          productType: product.type,
          category: product.category,
          unitPrice: product.price,
          quantity: item.quantity,
          subtotal: roundMoney(product.price * item.quantity),
          livePetSnapshot: product.livePet || null,
        };
      });

      orderItems.forEach((item) => {
        const product = store.products.get(item.productId);
        product.stock -= item.quantity;
        product.updatedAt = new Date().toISOString();
      });

      cartItems.forEach((item) => store.cartItems.delete(item.id));

      const totalAmount = roundMoney(orderItems.reduce((sum, item) => sum + item.subtotal, 0));
      const user = store.users.get(userId);
      const discountRate = memberDiscountRate(user?.memberLevel);
      const discountAmount = roundMoney(totalAmount * discountRate);
      const payAmount = roundMoney(totalAmount - discountAmount);
      const now = new Date().toISOString();
      const order = {
        id: newId('ord'),
        orderNo: `PE${Date.now()}${Math.floor(Math.random() * 1000).toString().padStart(3, '0')}`,
        userId,
        status: 0,
        statusName: orderStatusName(0),
        totalAmount,
        discountAmount,
        payAmount,
        addressSnapshot: input.addressSnapshot || {
          receiver: user?.displayName || user?.username || 'Demo User',
          phone: user?.phone || '18800000000',
          detail: 'Pet-Emarket demo address',
        },
        items: orderItems,
        review: null,
        refund: null,
        statusLogs: [],
        createdAt: now,
        updatedAt: now,
      };
      appendOrderLog(order, null, 0, 'USER', '创建订单');
      store.orders.set(order.id, order);
      return order;
    },
    listOrders(currentUser) {
      const orders = [...store.orders.values()];
      if (currentUser.role === 'ADMIN' || currentUser.role === 'MERCHANT') {
        return orders.sort(orderSort);
      }
      return orders.filter((order) => order.userId === currentUser.id).sort(orderSort);
    },
    findOrderById(id) {
      return store.orders.get(id) || null;
    },
    transitionOrder(id, action, actor, input = {}) {
      const order = store.orders.get(id);
      if (!order) {
        return null;
      }
      const transition = resolveOrderTransition(order.status, action, actor.role, input);
      if (!transition.allowed) {
        throw new Error(transition.reason);
      }
      const from = order.status;
      order.status = transition.to;
      order.statusName = orderStatusName(order.status);
      order.updatedAt = new Date().toISOString();
      if (action === 'review') {
        order.review = {
          rating: Number(input.rating || 5),
          content: input.content || '',
          createdAt: order.updatedAt,
        };
      }
      if (action === 'applyRefund') {
        order.refund = {
          reason: input.reason || '用户申请退单',
          auditStatus: 'PENDING',
          auditRemark: '',
          createdAt: order.updatedAt,
        };
      }
      if (action === 'auditRefund') {
        order.refund = {
          ...(order.refund || {}),
          auditStatus: input.approved ? 'APPROVED' : 'REJECTED',
          auditRemark: input.auditRemark || '',
          auditedAt: order.updatedAt,
        };
      }
      if (action === 'adminRefund') {
        order.refund = {
          reason: input.reason || '管理员直接退单',
          auditStatus: 'DIRECT_REFUND',
          auditRemark: input.auditRemark || '',
          auditedAt: order.updatedAt,
        };
      }
      appendOrderLog(order, from, order.status, actor.role, transition.reason);
      return order;
    },
  };
}

function findUserByUsername(store, username) {
  const normalized = String(username || '').trim().toLowerCase();
  return [...store.users.values()].find((user) => user.username.toLowerCase() === normalized) || null;
}

function createUserRecord(input) {
  const now = new Date().toISOString();
  const passwordState = hashPassword(input.password || 'ChangeMe@123456');
  return {
    id: newId('usr'),
    username: required(input.username, 'username'),
    displayName: input.displayName || input.username,
    phone: input.phone || '',
    email: input.email || '',
    role: input.role || 'CUSTOMER',
    memberLevel: input.memberLevel || 'NORMAL',
    status: input.status || 'ACTIVE',
    passwordHash: passwordState.passwordHash,
    passwordSalt: passwordState.passwordSalt,
    createdAt: now,
    updatedAt: now,
  };
}

function createProductRecord(input) {
  const now = new Date().toISOString();
  return {
    id: newId('prd'),
    storeId: input.storeId || 'store-001',
    name: required(input.name, 'name'),
    type: input.type || 'GOODS',
    category: input.category || 'General',
    price: Number(input.price || 0),
    stock: Number(input.stock || 0),
    status: input.status || 'DRAFT',
    coverUrl: input.coverUrl || '',
    description: input.description || '',
    tags: Array.isArray(input.tags) ? input.tags : [],
    livePet: input.livePet || null,
    createdAt: now,
    updatedAt: now,
  };
}

function hydrateCartItem(store, item) {
  const product = store.products.get(item.productId);
  if (!product) {
    return null;
  }
  return {
    ...item,
    product: {
      id: product.id,
      name: product.name,
      type: product.type,
      category: product.category,
      price: product.price,
      stock: product.stock,
      status: product.status,
      description: product.description,
      livePet: product.livePet,
    },
    subtotal: roundMoney(product.price * item.quantity),
  };
}

function resolveOrderTransition(status, action, role, input) {
  const adminRoles = ['ADMIN', 'MERCHANT'];
  const transitions = {
    pay: { from: [0], to: 1, roles: ['CUSTOMER', 'ADMIN'], reason: '支付成功' },
    ship: { from: [1], to: 2, roles: adminRoles, reason: '管理员发货' },
    receive: { from: [2], to: 3, roles: ['CUSTOMER', 'ADMIN'], reason: '用户确认收货' },
    review: { from: [3], to: 4, roles: ['CUSTOMER', 'ADMIN'], reason: '用户评价完成' },
    cancel: { from: [0, 1], to: -1, roles: ['CUSTOMER', 'ADMIN'], reason: input.reason || '取消订单' },
    applyRefund: { from: [2, 3], to: -2, roles: ['CUSTOMER', 'ADMIN'], reason: input.reason || '用户申请退单' },
    adminRefund: { from: [3, 4], to: -4, roles: adminRoles, reason: input.reason || '管理员直接退单' },
  };

  if (action === 'auditRefund') {
    if (!adminRoles.includes(role)) return { allowed: false, reason: 'Only admin or merchant can audit refund' };
    if (status !== -2) return { allowed: false, reason: 'Only refund requests can be audited' };
    return {
      allowed: true,
      to: input.approved ? -3 : Number(input.rollbackStatus || 2),
      reason: input.approved ? '退单审核通过' : input.auditRemark || '退单审核不通过，回到原状态',
    };
  }

  const rule = transitions[action];
  if (!rule) return { allowed: false, reason: 'Unknown order action' };
  if (!rule.from.includes(status)) return { allowed: false, reason: `Cannot ${action} from status ${status}` };
  if (!rule.roles.includes(role)) return { allowed: false, reason: 'No permission for this order action' };
  return { allowed: true, to: rule.to, reason: rule.reason };
}

function appendOrderLog(order, fromStatus, toStatus, operatorRole, reason) {
  order.statusLogs.push({
    id: newId('log'),
    fromStatus,
    toStatus,
    toStatusName: orderStatusName(toStatus),
    operatorRole,
    reason,
    createdAt: new Date().toISOString(),
  });
}

function orderStatusName(status) {
  return {
    0: '已下单/待支付',
    1: '已支付/待发货',
    2: '已发货/待收货',
    3: '已收货/待评价',
    4: '已评价/完成',
    '-1': '取消订单',
    '-2': '申请退单',
    '-3': '退单成功',
    '-4': '管理员直接退单',
  }[String(status)] || '未知状态';
}

function memberDiscountRate(memberLevel) {
  return {
    NORMAL: 0,
    VIP: 0.05,
    SVIP: 0.1,
  }[memberLevel] || 0;
}

function roundMoney(value) {
  return Math.round(Number(value || 0) * 100) / 100;
}

function orderSort(a, b) {
  return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
}

function hashPassword(password, salt = crypto.randomBytes(16).toString('hex')) {
  return {
    passwordSalt: salt,
    passwordHash: crypto.pbkdf2Sync(String(password), salt, 120000, 32, 'sha256').toString('hex'),
  };
}

function newId(prefix) {
  const bytes = crypto.randomBytes(8).toString('hex');
  return `${prefix}_${bytes}`;
}

function required(value, name) {
  const text = String(value || '').trim();
  if (!text) {
    throw new Error(`${name} is required`);
  }
  return text;
}

function sanitizeUser(user) {
  const { passwordHash, passwordSalt, ...safeUser } = user;
  return safeUser;
}

module.exports = { createInMemoryStore };
