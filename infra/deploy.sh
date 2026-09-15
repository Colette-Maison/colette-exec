#!/bin/bash
# Run this ON THE VM (as the eric_colette_family user, via
# `gcloud compute ssh colette-exec --tunnel-through-iap`) after populating
# the real secret values (see infra/README.md). Pulls this app's Secret
# Manager secrets into a root .env via the VM's attached colette-exec-app
# service account (no key file involved — metadata-server credentials),
# then brings the stack up.
set -euo pipefail
cd /opt/colette-exec

fetch() { gcloud secrets versions access latest --secret="$1"; }

{
  echo "ANTHROPIC_API_KEY=$(fetch colette-exec-anthropic-api-key)"
  echo "BACKEND_SHARED_SECRET=$(fetch colette-exec-backend-shared-secret)"
  echo "AUTH_SECRET=$(fetch colette-exec-auth-secret)"
  echo "AUTH_GOOGLE_ID=$(fetch colette-exec-google-client-id 2>/dev/null || true)"
  echo "AUTH_GOOGLE_SECRET=$(fetch colette-exec-google-client-secret 2>/dev/null || true)"
  echo "OE_PUBLIC_DEPLOYMENT=1"
} > .env
chmod 600 .env

sudo docker compose -f docker/docker-compose.yml --env-file .env up -d --build
