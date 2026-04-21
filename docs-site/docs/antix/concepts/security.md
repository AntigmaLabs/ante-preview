---
title: "Privacy, Security & Data Retention"
description: "What Antix persists, what it doesn't, and the operational guards around billing."
sidebar_position: 5
---

# Privacy, Security & Data Retention

Antix is designed for **fail-closed billing** and **credential isolation**, not blanket zero-retention. Be explicit with your team about what the platform persists so compliance expectations match reality.

## What Antix persists

- **Request and response bodies** are recorded on every proxy call for cost attribution, retry-safety, and the admin analytics timeline. This is a deployment decision, not an opt-in toggle today.
- **Billing events** — token counts, model, user, organization, virtual-key identifiers, TTFT, duration — are persisted securely.
- **Identity state** — OAuth sessions, refresh-token families, and blocklist entries — is persisted for session management and revocation.

If your compliance posture requires payload redaction, raise it with whoever administers your Antix deployment — redaction is typically handled at the log sink or by running Antix behind a redacting gateway. Antix does not currently ship a first-class payload-scrubbing toggle.

## What Antix does not do

- **No model training.** Traffic through Antix is never used to train Antigma models. You must still verify the upstream provider's data policy for each model you route to.
- **No credential leakage to logs.** Virtual keys are stored securely; plaintext is returned exactly once at creation.
- **No silent unbilled traffic.** If the billing backend is unreachable, Antix fails closed with `503` rather than serving requests it can't meter.
