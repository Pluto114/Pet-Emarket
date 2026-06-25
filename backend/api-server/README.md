# Pet-Emarket API Server

This is the first runnable backend skeleton for team integration. It uses only Node.js built-in modules so the team can start without installing backend dependencies.

## Run

```powershell
cd backend/api-server
node src/server.js
```

Default URL:

```text
http://localhost:8080
```

## Demo Accounts

```text
admin / Admin@123456
demo  / Demo@123456
```

## Core APIs

```text
GET    /api/v1/health
POST   /api/v1/auth/login
POST   /api/v1/auth/register
GET    /api/v1/auth/me
GET    /api/v1/users
POST   /api/v1/users
GET    /api/v1/users/{id}
PUT    /api/v1/users/{id}
DELETE /api/v1/users/{id}
GET    /api/v1/products
POST   /api/v1/products
GET    /api/v1/products/{id}
PUT    /api/v1/products/{id}
DELETE /api/v1/products/{id}
```

Mutation APIs require `Authorization: Bearer <token>`.
