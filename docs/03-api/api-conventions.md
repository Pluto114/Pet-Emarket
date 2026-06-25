# API Conventions

## Base URL

```text
http://localhost:8080
```

All business APIs use the `/api/v1` prefix.

## Response Format

```json
{
  "success": true,
  "code": "000000",
  "message": "success",
  "data": {},
  "traceId": "trace-id",
  "timestamp": 1783651200000
}
```

## Authentication

Login returns a signed bearer token. Mutation APIs require:

```text
Authorization: Bearer <token>
```

## Error Code Groups

```text
000000 success
10xxxx user and authentication errors
20xxxx product and store errors
30xxxx order and payment errors
40xxxx AI and recommendation errors
50xxxx system errors
```
