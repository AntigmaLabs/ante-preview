---
title: "Ante Control Plane"
description: "Govern local coding agents with PKCE, attribution, and revocation."
sidebar_position: 1
---

# Native Agent Integration

Antix is the centralized control plane for the **Ante CLI**, bringing enterprise governance to local coding agents.

## Connecting Ante to Antix

Developers authenticate their local Ante instance against your Antix server:

1. Start the `ante` CLI.
2. Type `/connect`.
3. Select **Antix** from the menu.

This securely authenticates your local agent with the Antix control plane, granting it a temporary access token that automatically refreshes as needed.

## Benefits

- **Cost attribution** — every prompt run from an engineer's Ante CLI is attributed to their user ID in the billing ledger and analytics timeline.
- **Model governance** — restrict which models local agents can use via the `models` allow-list on the user's Virtual Key, or via organization-level defaults.
- **Instant offboarding** — when an employee leaves, revoke their access in the Antix dashboard. The CLI disconnects within seconds when a member is removed via the portal.
