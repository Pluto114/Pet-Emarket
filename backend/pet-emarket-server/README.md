# Pet-Emarket Java Backend

This is the official backend implementation for the course project. The old `backend/api-server` Node service is only an early mock server and should not be extended as the formal backend.

## Tech Stack

- Java 17
- Spring Boot 3.3
- Spring Web
- Spring Security
- Spring Data JPA
- MySQL
- Flyway
- Manual HMAC JWT implementation based on JDK crypto APIs

## Persistence

The backend connects to MySQL by default. Runtime business data must be stored in MySQL, including products, carts, users, orders, addresses, payments, points and behavior logs.

Default datasource values are defined in `src/main/resources/application.yml`:

```powershell
$env:DB_HOST="localhost"
$env:DB_PORT="3306"
$env:DB_NAME="pet_emarket"
$env:DB_USERNAME="root"
$env:DB_PASSWORD="Zhaojerry331!"
mvn spring-boot:run
```

Flyway applies schema migrations from `src/main/resources/db/migration`. `DataInitializer` only inserts missing demo accounts, stores and seed products when needed; it does not reset tables on startup.

## Run

Install JDK 17 and Maven first.

```powershell
cd backend/pet-emarket-server
mvn spring-boot:run
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

## Implemented APIs

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

GET    /api/v1/cart/items
POST   /api/v1/cart/items
PUT    /api/v1/cart/items/{id}
DELETE /api/v1/cart/items/{id}

GET    /api/v1/orders
POST   /api/v1/orders
GET    /api/v1/orders/{id}
PUT    /api/v1/orders/{id}/pay
PUT    /api/v1/orders/{id}/ship
PUT    /api/v1/orders/{id}/receive
PUT    /api/v1/orders/{id}/review
PUT    /api/v1/orders/{id}/cancel
PUT    /api/v1/orders/{id}/apply-refund
PUT    /api/v1/orders/{id}/audit-refund
PUT    /api/v1/orders/{id}/admin-refund
```

Mutation APIs require:

```text
Authorization: Bearer <token>
```
