---
title: "Welcome to Antix"
description: "Antix is an enterprise-grade LLM Proxy, Identity Provider (IdP), and Workspace Manager built by Antigma."
sidebar_position: 1
---

# Introduction to Antix

Welcome to **Antix**, Antigma's enterprise-grade LLM Proxy, Identity Provider, and Workspace Manager.

While **Ante** brings powerful autonomous AI capabilities directly to your local terminal, **Antix** is the collaborative backend infrastructure that makes AI scalable, secure, and observable for teams. It acts as a unified gateway to manage models, govern organizations, issue budget-capped API keys, and track AI spend across your entire company.

---

## What is Antix?

Antix is a high-performance proxy built in Rust that sits between your applications (or CLI agents like Ante) and foundational LLM providers (OpenAI, Anthropic, Gemini, Alibaba Qwen, etc.). 

It abstracts away the complexity of managing multiple AI vendor billing accounts, standardizes API requests, and provides a centralized Identity Provider (IdP) for your entire engineering organization.

## Core Concepts

Understanding these six pillars will help you get the most out of Antix:

### 1. Universal Model Routing & OpenAI Compatibility
Antix acts as a seamless drop-in replacement for OpenAI. It translates provider-specific quirks into a standardized API schema. Whether you are routing a request to `anthropic/claude-3-5-sonnet` or `alibaba/qwen-max`, your application code remains identical. 
* **Seamless Streaming:** Antix manages underlying streaming state machines to ensure Server-Sent Events (SSE) behave predictably, regardless of the upstream provider.
* **Bring Your Own Key (BYOK):** Want to use your own negotiated rates? Pass a provider-specific header (e.g., `X-Antix-Provider: alibaba`) to route requests securely through your own accounts.

### 2. Organization & Workspace Management
Antix is built from the ground up for multi-tenancy. **Organizations** allow you to group users, projects, and billing boundaries securely.
* **Role-Based Access Control (RBAC):** Assign roles (Admin, Member, Viewer) to control who can provision keys or view financial analytics.
* **Workspaces:** Create isolated environments within an Org for different projects (e.g., `Frontend-Prod`, `Ante-CLI-Agents`).

### 3. Virtual Keys & Hard Budgets
Never share raw provider API keys in plaintext again. Antix allows Workspace Admins to issue **Virtual Keys** (`sk-vk-...`) tied to specific users, workspaces, or agents.
* **Granular Guardrails:** Restrict a Virtual Key to specific models or providers.
* **Fail-Closed Budgets:** Set strict spend limits (daily, monthly, or absolute). Our Redis-backed atomic billing system instantly blocks requests once a budget is hit, physically preventing cost overruns.

### 4. Comprehensive Observability & Telemetry
Track the metrics that matter for production AI. Antix is instrumented with OpenTelemetry to provide deep visibility into your AI workloads.
* **Time-to-First-Token (TTFT):** Monitor generation latency across different models and regions.
* **Zero Data Loss:** Telemetry and billing events are backed by a Dead Letter Queue (DLQ) and asynchronously flushed to ClickHouse, ensuring your hot-path latency remains ultra-low without sacrificing accurate spend tracking.

### 5. Built-in Identity Provider (IdP)
Antix isn't just an API proxy; it is a full OAuth 2.0 Identity Provider. You can integrate Antix authentication into your internal web tools or CLI applications.
* **SSO Integration:** Native support for Google and GitHub authentication.
* **Secure Sessions:** Robust session management utilizing Refresh Token Rotation (RTR) and secure cross-domain cookies.

### 6. Native Agent Integration (The Ante Control Plane)
For organizations using the **Ante CLI**, Antix serves as the centralized governance layer. Using our native OAuth PKCE flow, developers can securely authenticate their local Ante agents against your corporate Antix server. This allows admins to control which models local agents can use, track code-generation spend per developer, and revoke access instantly if an employee leaves.

---

## Antix vs. Ante: Which do you need?

Many teams use both, but they serve entirely different purposes:

| Feature | Ante | Antix |
| :--- | :--- | :--- |
| **Primary Role** | Autonomous CLI Coding Agent | Enterprise LLM Gateway & Dashboard |
| **Target Audience** | Individual Developers, Engineers | Workspace Admins, Product Teams, DevOps |
| **Core Function** | Writes code, explores repos, runs tests | Routes LLM requests, enforces budgets, manages users |
| **Deployment** | Installed locally via terminal | Hosted server / GCP / Local Docker |

---

## Choose Your Path

Antix documentation is structured around your specific role and goals. Select the path that best matches what you are trying to do:

### 🛠️ For Developers: Build & Integrate
*You want to query models, use Virtual Keys, or integrate Antix Auth into your app.*
* **[Developer Quickstart](/antix/concepts#routing):** Make your first API call to the Antix proxy.
* **[Using Virtual Keys & BYOK](/antix/concepts#byok):** How to authenticate your requests and specify providers.
* **[Identity & OAuth 2.0](/antix/concepts#auth):** Integrate Antix login (PKCE flow) into your external web apps.

### 🏢 For Administrators: Manage Teams & Spend
*You are managing a team, setting up budgets, and reviewing analytics.*
* **[Organization Setup](/antix/concepts#organizations):** Create workspaces and manage team member roles.
* **[Budgeting & Guardrails](/antix/concepts#budgets):** Issue Virtual Keys and set hard spend limits to prevent bill shock.
* **[Analytics & Observability](/antix/concepts#analytics):** View TTFT, error rates, and cost tracking dashboards.

### ⚙️ For Operators: Deploy & Host Antix
*You are an infrastructure engineer tasked with self-hosting the Antix stack.*
* **[Local Docker Deployment](/antix/ops/local-docker):** Spin up Antix, PostgreSQL, ClickHouse, and Redis via `docker-compose`.
* **[GCP Production Deployment](/antix/ops/gcp-deploy):** A step-by-step guide to deploying Antix securely on Google Cloud Run and Cloud SQL.
* **[Environment Configuration](/antix/ops/configuration):** Comprehensive reference for `ANTIX_ENV` and core server flags.
