const crypto = require('crypto');

function createInMemoryStore() {
  const store = {
    users: new Map(),
    products: new Map(),
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
