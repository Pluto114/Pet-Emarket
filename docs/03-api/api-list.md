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

## Cart

| Method | Path | Auth | Role | Description |
|---|---|---|---|---|
| GET | `/api/v1/cart/items` | Yes | Any logged-in user | List current user's cart items |
| POST | `/api/v1/cart/items` | Yes | Any logged-in user | Add product to cart |
| PUT | `/api/v1/cart/items/{id}` | Yes | Cart owner | Update quantity |
| DELETE | `/api/v1/cart/items/{id}` | Yes | Cart owner | Remove cart item |

## Orders

| Method | Path | Auth | Role | Description |
|---|---|---|---|---|
| GET | `/api/v1/orders` | Yes | Customer sees self, admin/merchant sees all | List orders |
| POST | `/api/v1/orders` | Yes | Any logged-in user | Create order from cart |
| GET | `/api/v1/orders/{id}` | Yes | Owner, ADMIN, MERCHANT | Read order |
| PUT | `/api/v1/orders/{id}/pay` | Yes | Owner, ADMIN | Pay order |
| PUT | `/api/v1/orders/{id}/ship` | Yes | ADMIN, MERCHANT | Ship order |
| PUT | `/api/v1/orders/{id}/receive` | Yes | Owner, ADMIN | Confirm receipt |
| PUT | `/api/v1/orders/{id}/review` | Yes | Owner, ADMIN | Review order |
| PUT | `/api/v1/orders/{id}/cancel` | Yes | Owner, ADMIN | Cancel order from status 0 or 1 |
| PUT | `/api/v1/orders/{id}/apply-refund` | Yes | Owner, ADMIN | Apply refund from status 2 or 3 |
| PUT | `/api/v1/orders/{id}/audit-refund` | Yes | ADMIN, MERCHANT | Approve or reject refund request |

Order status values:

```text
0  已下单/待支付
1  已支付/待发货
2  已发货/待收货
3  已收货/待评价
4  已评价/完成
-1 取消订单
-2 申请退单
-3 退单成功
-4 管理员直接退单
```
