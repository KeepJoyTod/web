# K6 Scripts

This directory contains runnable K6 scripts for ProjectKu.

## Scripts

- `k6/api-load.js`: mixed browse load for categories, product list, product detail, and optional authenticated reads.
- `k6/checkout-smoke.js`: low-concurrency write-path smoke for cart and checkout.

## First Run

Start dependencies and backend first:

```powershell
docker compose up -d
cd back
mvn spring-boot:run
```

Then run the prepared baseline command:

```powershell
.\scripts\run-first-k6.ps1
```

## Direct Commands

Mixed browse load:

```powershell
.\scripts\run-k6-and-record.ps1 `
  -BaseUrl "http://127.0.0.1:8080/api" `
  -K6Script "k6/api-load.js" `
  -Title "K6 API mixed browse load" `
  -Environment "local-windows" `
  -ExtraK6Args @("--vus", "20", "--duration", "3m")
```

Checkout smoke, keep concurrency low:

```powershell
.\scripts\run-k6-and-record.ps1 `
  -BaseUrl "http://127.0.0.1:8080/api" `
  -K6Script "k6/checkout-smoke.js" `
  -Title "K6 checkout smoke" `
  -Environment "local-windows" `
  -ExtraK6Args @("--vus", "1", "--duration", "1m")
```

## Environment Variables

- `BASE_URL`: API base URL, defaults to `http://127.0.0.1:8080/api`
- `ACCOUNT`: login account, defaults to `user@example.com`
- `PASSWORD`: login password, defaults to `123456`
- `ENABLE_AUTH`: set to `false` to skip authenticated reads in `api-load.js`
- `VUS`: default virtual users if not passed via CLI
- `DURATION`: default duration if not passed via CLI
- `STAGES`: optional ramping stages, format `30s:10,1m:30,3m:50`
- `THINK_TIME`: sleep seconds between iterations, defaults to `1`
