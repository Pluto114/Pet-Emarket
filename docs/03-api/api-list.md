# API List

## Health

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/health` | No | Backend health check |

## Auth

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/api/v1/auth/login` | No | Login with username and password |
| POST | `/api/v1/auth/register` | No | Register customer account |
| GET | `/api/v1/auth/me` | Yes | Read current user profile |

## Users

| Method | Path | Auth | Role | Description |
|---|---|---|---|---|
| GET | `/api/v1/users` | Yes | ADMIN | List users |
| POST | `/api/v1/users` | Yes | ADMIN | Create user |
| GET | `/api/v1/users/{id}` | Yes | ADMIN or self | Read user |
| PUT | `/api/v1/users/{id}` | Yes | ADMIN or self | Update user |
| DELETE | `/api/v1/users/{id}` | Yes | ADMIN | Delete user |

## Products

| Method | Path | Auth | Role | Description |
|---|---|---|---|---|
| GET | `/api/v1/products` | No | Public | List products |
| GET | `/api/v1/products/{id}` | No | Public | Read product |
| POST | `/api/v1/products` | Yes | ADMIN, MERCHANT | Create product |
| PUT | `/api/v1/products/{id}` | Yes | ADMIN, MERCHANT | Update product |
| DELETE | `/api/v1/products/{id}` | Yes | ADMIN, MERCHANT | Delete product |

Product type values:

```text
GOODS
PET_LIVE
```

Product status values:

```text
DRAFT
ON_SALE
OFF_SALE
```
