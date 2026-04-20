---
title: "Core Concepts"
sidebar_position: 2
---

# Antix: In-Depth Core Concepts & Technical Reference

This document provides detailed instructions, code examples, API specifications, and technical context for the core capabilities of Antix. It is designed to give developers, administrators, and DevOps engineers a comprehensive understanding of the platform's architecture.

---

## 1. Universal Model Routing & BYOK {#routing}

Antix provides a seamless OpenAI-compatible API. It automatically translates requests and normalizes streaming state machines (SSE) across different LLM providers (Anthropic, Google Gemini, Alibaba Qwen, xAI, etc.).

### Base URLs & Endpoints
Antix exposes standard OpenAI-compatible endpoints.
* **Production Base URL:** `https://api.antigma.ai/v1`
* **Local Development:** `http://127.0.0.1:8080/v1`

**Core Proxy Endpoints:**
* `POST /v1/chat/completions` (Text generation & streaming)
* `GET /v1/models` (List currently supported and dynamically priced models)

### Using Antix as a Drop-in Replacement
You do not need new SDKs to use Antix. Simply change the `base_url` in your existing OpenAI SDK and provide your Antix Virtual Key.

**Python Example (OpenAI SDK):**
```python
from openai import OpenAI

client = OpenAI(
    base_url="https://api.antigma.ai/v1", # Point to your Antix instance
    api_key="sk-vk-123456789"             # Your Antix Virtual Key
)

response = client.chat.completions.create(
    model="claude-3-5-sonnet-20240620",   # Use ANY model supported by Antix
    messages=[{"role": "user", "content": "Write a rust function for fibonacci."}],
    stream=True
)

for chunk in response:
    print(chunk.choices[0].delta.content, end="")
```

### Bring Your Own Key (BYOK) {#byok}
If you have negotiated direct rates with a provider but still want the observability and routing benefits of Antix, you can use BYOK mode. Pass your provider's raw API key via the `Authorization` header, and explicitly define the provider using the `X-Antix-Provider` header.

**cURL Example (Routing to Alibaba Qwen):**
```bash
curl -X POST https://api.antigma.ai/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ALIBABA_DASHSCOPE_KEY" \
  -H "X-Antix-Provider: alibaba" \
  -d '{
    "model": "qwen-max",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```
*Technical Note: If you omit `X-Antix-Provider` with a BYOK key, Antix's `infer_from_key()` middleware attempts to guess the provider based on key prefixes (e.g., defaulting to OpenAI). For providers without unique prefixes like Alibaba, omitting the header will result in an upstream `401 Unauthorized`.*

---

## 2. Organization & Workspace Management {#organizations}

Antix is designed for multi-tenant environments. **Organizations** form the top-level billing boundary, while **Workspaces** provide isolated environments for different teams, projects, or deployment stages.

### The CBAC Role Model
Antix enforces Capability-Based Access Control (CBAC) without adding latency to the hot path. Roles include:
*   **Org Admin:** Full control over billing, workspaces, and all users.
*   **Workspace Admin:** Can issue Virtual Keys, adjust rate limits, and view analytics for their specific workspace.
*   **Member:** Can consume APIs using provided keys but cannot view budgets or analytics.

### Provisioning a Workspace (Admin API)
Administrators can programmatically provision workspaces.

```bash
curl -X POST https://api.antigma.ai/api/v1/workspaces \
  -H "Authorization: Bearer sk-antix-master-..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Production Frontend",
    "description": "Workspace for the customer-facing web app",
    "enforce_strict_budgets": true
  }'
```

---

## 3. Virtual Keys, Rate Limits & Hard Budgets {#budgets}

Never distribute root provider keys (e.g., OpenAI `sk-...`). Instead, Antix issues **Virtual Keys** (`sk-vk-...`). These keys act as middleware interceptors, validating budgets and rate limits in Redis before routing traffic.

### Creating a Key with Budgets and Rate Limits
You can restrict a Virtual Key by budget, model allowed lists, Requests Per Minute (RPM), and Tokens Per Minute (TPM).

**cURL Example:**
```bash
curl -X POST https://api.antigma.ai/api/v1/virtual-keys \
  -H "Authorization: Bearer sk-antix-master-..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "CI/CD Testing Key",
    "workspace_id": "ws_987654",
    "limits": {
      "budget_usd_monthly": 50.00,
      "rpm_limit": 60,
      "tpm_limit": 100000,
      "allowed_models": ["gpt-4o-mini", "claude-3-haiku-20240307"]
    },
    "expires_in_days": 30
  }'
```

### The BillingGuard & Token Estimation
1. **Pre-flight Estimation:** When a request arrives, Antix parses the prompt and estimates the token count locally.
2. **Atomic Reservation:** Antix uses a Redis Lua script to reserve the estimated cost atomically against the workspace budget.
3. **Async Settlement:** Once the upstream provider returns the final token usage (or the stream completes), Antix calculates the exact cost and asynchronous settles the difference in Redis. If the stream fails mid-way, the unused reserved budget is returned.

---

## 4. Error Handling & Observability {#analytics}

Because Antix sits on the critical path of your applications, understanding its error codes and observability metrics is essential.

### Standardized Error Codes
Antix intercepts and standardizes errors across all providers:
*   `400 Bad Request`: Malformed payload or requesting a model not supported by the upstream provider.
*   `401 Unauthorized`: Invalid Virtual Key, or the JWT `jti` is found in the Redis blocklist.
*   **`402 Payment Required`**: The Virtual Key or Workspace has exceeded its defined `budget_usd_monthly`.
*   **`429 Too Many Requests`**: The request exceeded the RPM or TPM rate limits set on the Virtual Key.
*   **`503 Service Unavailable`**: Triggered by Antix's **Fail-Closed** architecture. If the Redis billing backend goes down, Antix refuses to route traffic to prevent unbilled usage (unless explicitly overridden by `ANTIX_DANGER_ALLOW_UNBILLED_USAGE=true`).

### Telemetry & ClickHouse DLQ
Antix offloads analytics via a Dead Letter Queue (DLQ) to ensure zero impact on your hot path.
*   **TTFT (Time-to-First-Token):** Tracked automatically for all streaming requests.
*   **TPS (Tokens Per Second):** Tracked to evaluate provider health.
*   **Cost Reconciliations:** Antix periodically runs a background process (`antix_billing::budget::Reserver`) to reconcile Redis fast-budgets against actual ClickHouse billing logs to prevent budget drift.

---

## 5. Privacy, Security & Data Retention

For compliance, Antix enforces strict data security policies by default, matching or exceeding zero-retention standards.

*   **Zero-Retention Policy:** By default, Antix **does not log or retain prompt payloads or model responses**. Inference bodies are scrubbed from all ClickHouse logs and OpenTelemetry traces. 
*   **In-Memory Processing:** Payload data is only held in memory in the Rust Axum server long enough to be proxied to the upstream provider and streamed back to the client.
*   **No Training:** Data passed through Antix is never used for model training. (Note: You must still verify the data policies of the specific upstream provider you route to).
*   **Opt-In Debugging:** Workspace Admins can explicitly opt-in to payload logging for debugging purposes, but this must be manually configured per-workspace.

---

## 6. Built-in Identity Provider (IdP) {#auth}

Antix is a full **OAuth 2.0 Identity Provider**. For internal AI tools (like chat interfaces), use Antix to handle authentication.

### Authentication Flow (PKCE)
1.  **Initiate Login:** Your app redirects the user to Antix.
    `GET https://api.antigma.ai/auth/public/login?client_id=my-app&redirect_uri=https://my-app.com/callback`
2.  **User Authenticates:** Login via Google/GitHub.
3.  **Token Exchange:** 
    ```bash
    curl -X POST https://api.antigma.ai/oauth/token \
      -d "grant_type=authorization_code" \
      -d "code=AUTHORIZATION_CODE"
    ```

### JWT Specifications & Security
Antix issues an `RS256` JWT with a 15-minute TTL and utilizes **Refresh Token Rotation (RTR)**.
*   **Audience (`aud`):** `antix-portal` for web apps, `ante-cli` for agents.
*   **Key ID (`kid`):** `antix-1`
*   **Revocation:** When a user logs out, their JWT ID (`jti`) is instantly added to a Redis blocklist (`antix:jti:blocklist:{jti}`), ensuring stolen tokens are useless even before they expire.

---

## 7. Native Agent Integration (The Ante Control Plane)

Antix acts as the centralized control plane for the **Ante CLI**, bringing governance to local coding agents. 

### Connecting Ante to Antix
Developers connect their local Ante instance to your corporate Antix server:
```bash
ante auth login
```
This triggers a local OAuth flow, storing a Refresh Token in `~/.antix/auth.json`. Ante uses this to synthesize temporary Virtual Keys for code generation.

### Benefits
*   **Cost Attribution:** Every prompt run by an engineer's Ante CLI is tracked in Antix and attributed to their specific user ID.
*   **Instant Offboarding:** When an employee leaves, an Admin revokes their access in the Antix dashboard. Because Ante relies on Antix's RTR, the developer's local CLI is instantly disconnected from the LLM APIs, preventing unauthorized post-employment usage.
