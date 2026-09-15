# colette-exec infra

Terraform for this app's slice of the shared `Colette` GCP project
(`valued-lyceum-508616-g0`). Separate from `chatelaine`'s own
`infra/terraform` (family product) — separate state, separate service
account, separate VPC path (`default`, not `colette-vpc`) — so this app's
infra can be applied, inspected, or destroyed without touching theirs.

## Why no Cloud SQL

The app's default persistence is SQLite-on-a-volume (`episodic_memory.db`)
plus ChromaDB (also file-based). There is no Postgres/SQLAlchemy code path
in this codebase at all. For three internal users, that's sufficient — this
Terraform does not provision a database on the family product's `colette-pg`
Cloud SQL instance. Revisit only if there's a concrete scale/concurrency
reason to, not by default.

## What's here

- `providers.tf` — provider config + API enablement (compute, secretmanager, iam)
- `iam.tf` — `colette-exec-app` service account, scoped `secretAccessor` grants
- `secrets.tf` — 5 Secret Manager containers (2 auto-populated by Terraform)
- `compute.tf` — the app VM (e2-medium, no external IP, IAP-only SSH)
- `nat.tf` — Cloud Router + NAT so the no-external-IP VM still has outbound internet
- `startup.sh` — first-boot Docker Engine + Compose plugin install

## Applying

```bash
cd infra/terraform
terraform init
env -u GOOGLE_APPLICATION_CREDENTIALS terraform plan -out=/tmp/plan.tfplan
env -u GOOGLE_APPLICATION_CREDENTIALS terraform apply /tmp/plan.tfplan
```

The `-u GOOGLE_APPLICATION_CREDENTIALS` unset matters on this machine: that
env var points at an unrelated service account key (`matcha-sa@...`), which
the Google provider picks up over your `gcloud auth login` account if you
don't unset it — you'll get a confusing `USER_PROJECT_DENIED` error instead
of an auth error.

State (`terraform.tfstate`) holds the two Terraform-generated secret values
in plaintext — it's gitignored, never commit it.

## Populating real secret values

Terraform creates empty containers for the credentials it can't safely
generate itself. Populate them from your own machine (never through an
agent session — the value would land in that session's transcript):

```bash
gcloud secrets versions add colette-exec-anthropic-api-key --data-file=- <<< "sk-ant-..."

# Phase 3, once a Google Cloud Console OAuth client exists for this app:
gcloud secrets versions add colette-exec-google-client-id     --data-file=- <<< "...apps.googleusercontent.com"
gcloud secrets versions add colette-exec-google-client-secret --data-file=- <<< "GOCSPX-..."
```

`colette-exec-backend-shared-secret` and `colette-exec-auth-secret` are
already populated — Terraform generated both.

## Deploying

The app is on the VM at `/opt/colette-exec`, copied over (not git-cloned —
the VM has no GitHub credential on it by design). `infra/deploy.sh` (copied
onto the VM at `/opt/colette-exec/deploy.sh`) pulls secrets into a root
`.env` via the VM's attached service account and runs `docker compose up`.

To redeploy after a code change, re-package and re-copy:

```bash
cd /Users/ericwest/colette-exec
tar --exclude='.git' --exclude='infra/terraform/.terraform' --exclude='node_modules' --exclude='.venv' --exclude='__pycache__' -czf /tmp/colette-exec-app.tar.gz .
gcloud compute scp /tmp/colette-exec-app.tar.gz colette-exec:/tmp/colette-exec-app.tar.gz --zone=us-central1-a --tunnel-through-iap
gcloud compute ssh colette-exec --zone=us-central1-a --tunnel-through-iap \
  --command='sudo tar -xzf /tmp/colette-exec-app.tar.gz -C /opt/colette-exec && sudo chown -R $(id -u):$(id -g) /opt/colette-exec'
```

Then, once secrets are populated, bring the stack up (pulls secrets into a
root `.env` via the VM's attached service account, then `docker compose up`):

```bash
gcloud compute ssh colette-exec --zone=us-central1-a --tunnel-through-iap --command='/opt/colette-exec/deploy.sh'
```

## Reaching it

The VM has no external IP; the only open ingress is SSH via IAP:

```bash
gcloud compute ssh colette-exec --zone=us-central1-a --tunnel-through-iap
```

The UI (port 3000) and API (port 8000, loopback-only in the compose file)
aren't reachable from the internet yet — no domain, no TLS, no
`BACKEND_ALLOWED_ORIGINS`/`AUTH_URL` set. For now, use an IAP TCP tunnel to
reach the UI from your own machine, e.g.:

```bash
gcloud compute start-iap-tunnel colette-exec 3000 --local-host-port=localhost:3000 --zone=us-central1-a
```

Real reachability for West/Wolf/Dingus (a domain + TLS in front of the UI,
`OE_PUBLIC_DEPLOYMENT`/`BACKEND_ALLOWED_ORIGINS`/`AUTH_URL` set accordingly)
is a Phase 3 decision — see the build brief.
