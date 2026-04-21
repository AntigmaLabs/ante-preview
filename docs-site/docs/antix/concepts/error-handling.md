---
title: "Error Handling"
description: "Standardized error codes."
sidebar_position: 4
---

# Error Handling

Because Antix sits on the critical path of your applications, understanding its error codes is essential.

## Standardized error codes {#errors}

Antix intercepts and standardizes errors across providers:

- **`400 Bad Request`** — malformed payload or requesting a model unsupported by the upstream.
- **`401 Unauthorized`** — missing or malformed `Authorization` header, unknown virtual key, revoked or deleted key, expired JWT (past the 15-minute TTL), or JWT `jti` found in the blocklist.
- **`402 Payment Required`** — the Virtual Key has exceeded its `max_budget` for the current `period`.
- **`429 Too Many Requests`** — the request exceeded the `rpm_limit` or `tpm_limit` on the Virtual Key.
- **`503 Service Unavailable`** — Antix's fail-closed path. Triggered when the billing backend is unreachable, or when a requested model has no pricing row (`model_not_priced`).
