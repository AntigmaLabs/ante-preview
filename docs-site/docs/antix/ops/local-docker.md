---
title: "Local Docker Deployment"
---

# Local Docker Deployment

Start infrastructure:
```bash
docker compose up -d postgres clickhouse redis
```

Initialize database:
```bash
docker compose exec -T postgres psql -U postgres -d antix < script/sql/insert_test_token.sql
```

Run Antix:
```bash
cargo run --release
```
