---
title: "GCP Production Deployment"
---


## Step 4: Automated CI/CD (GitHub)

To deploy Antix automatically from GitHub using Cloud Build:

1.  **Prerequisites**:
    *   Ensure the local deployment script `script/gcp_cloudrun_setup.sh` has been run at least once to create all necessary secrets in Secret Manager.
    *   **Dockerfile** must be present in the repository root.

2.  **Configure Permissions**:
    Run the helper script to grant Cloud Build the necessary permissions to deploy to Cloud Run:
    ```bash
    ./script/setup_cloudbuild_iam.sh
    ```

3.  **Connect GitHub Repository (Inline Configuration)**:
    *   Your admin has configured a Cloud Build trigger with an **Inline YAML** configuration.
    *   **Trigger Name**: `antix-deploy-on-push` (or similar)
    *   **Event**: Push to a branch (e.g., `^main$`)
    *   **Configuration**: Inline YAML (provided by admin)
    *   **Inline YAML Details**:
        *   Builds the Docker image: `us-west2-docker.pkg.dev/litellm-469819/cloud-run-source-deploy/antix:$COMMIT_SHA`
        *   Pushes the image to Artifact Registry.
        *   Deploys to Cloud Run service `antix` in `us-west2`.

    **IMPORTANT NOTE ON CONFIGURATION UPDATES:**
    The inline trigger configuration primarily updates the **container image**. It does *not* read any build configuration from the repository (e.g., `cloudbuild.yaml` is NOT used).

    If you need to update environment variables, secrets, or other service settings:
    1.  **Option A (Recommended)**: Use the Google Cloud Console to update the Cloud Run service revision directly.
    2.  **Option B (Local CLI)**: Run the following command locally to update configuration without redeploying a new image (or wait for the next push to deploy):
        ```bash
        gcloud run services update antix --region=us-west2 --set-env-vars=NEW_VAR=value
        ```
    3.  **Option C (Update Trigger)**: Ask your admin to update the Inline YAML in the Cloud Build Trigger settings to include new flags (e.g., `--set-env-vars`, `--set-secrets`) if they need to be permanent for every deployment.

4.  **Trigger a Build**:
    Push a change to the configured branch to trigger the deployment.

    **Note**: If you need to change secrets (e.g. API keys), update them locally using `gcp_deploy.env` and run `./script/gcp_cloudrun_setup.sh` (or update via Secret Manager console), then trigger a new build. The CI/CD pipeline does *not* update secrets from the repository.

## Step 5: Cloud SQL Backups & Point-in-Time Recovery (REQUIRED for prod)

**Why**: A misused admin UI once wiped 144 users in this project's dev DB
(post-mortem: `src/routes/admin/users.rs` + `ui/web/admin/public_users/`).
Application-layer hardening (typed-confirm, super-admin gate, cascade
cleanup) now blocks the easy paths, but automated DB-level backups are
the only recovery if any future bug, accidental `DELETE`, or compromised
admin session ever wipes user data. **Do not deploy to prod without this.**

### 5.1 One-time Cloud SQL configuration

Assuming Cloud SQL for PostgreSQL with instance name `antix-pg` in
`us-west2`:

```bash
gcloud sql instances patch antix-pg \
    --backup-start-time=09:00 \
    --enable-point-in-time-recovery \
    --retained-backups-count=14 \
    --retained-transaction-log-days=7 \
    --backup-location=us-west2
```

What this gives you:
- **Daily automated backups** retained for 14 days (RPO ≤ 24 h from a
  backup, far better via PITR below).
- **Point-in-time recovery** using write-ahead-log archival for the last
  7 days — effective RPO is **≤ 5 minutes**. You can restore the DB to
  any second within the window.
- Backups live in the same region as the instance (adjust
  `--backup-location` to a different region for DR).

Verify:

```bash
gcloud sql instances describe antix-pg \
  --format='value(settings.backupConfiguration.enabled,settings.backupConfiguration.pointInTimeRecoveryEnabled,settings.backupConfiguration.backupRetentionSettings.retainedBackups)'
# expect:  True    True    14
```

### 5.2 Restore runbook (rehearse this once before prod)

Create a clone of `antix-pg` at a specific timestamp — e.g., 5 minutes
before a destructive event at `2026-04-18T02:42:00Z`:

```bash
gcloud sql instances clone antix-pg antix-pg-restore-$(date +%s) \
    --point-in-time=2026-04-18T02:37:00Z
```

Then either re-point the app at the clone (fastest rollback) or dump the
specific rows you need (`pg_dump --table=users ...`) and re-import into
the production instance. **Do not delete the original instance** until
the clone is verified.

### 5.3 Alerting

Add a Cloud Monitoring alert that pages when backup success count drops
to zero over 24 h:

```
metric:  cloudsql.googleapis.com/database/backup/successful_backup_count
resource: cloudsql_database (instance_id = antix-pg)
condition: count < 1 over rolling 24h window
```

### 5.4 Pre-deploy checklist

Before the first prod push:
- [ ] `ANTIX_ENV=production` set on the Cloud Run service (disables
      `MASTER_KEY`, blocks staging-only escape hatches).
- [ ] Cloud SQL backups + PITR enabled, verified via the `describe` command above.
- [ ] Backup-missing alert created and routed to on-call.
- [ ] Restore runbook rehearsed in staging — restore a known-good state
      and confirm the app comes back up on the clone.
- [ ] A human has logged into `/ui/admin/public_users/` and confirmed:
      typed-confirm modal blocks a mis-click, and non-super-admin
      sessions see the "restricted" banner.

