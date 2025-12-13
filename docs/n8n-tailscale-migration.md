# n8n Tailscale Sidecar Migration Guide

This guide documents the conversion of the n8n service to a "zero-trust" deployment using a Tailscale sidecar.

## Overview

- **Goal**: Expose n8n ONLY via Tailscale (no public internet ports).
- **Security**: TLS termination handles by Tailscale Serve.
- **Networking**: n8n shares the network namespace of the Tailscale container.

## Prerequisites

1.  **Tailscale Auth Key**: Generate one at [login.tailscale.com/admin/settings/keys](https://login.tailscale.com/admin/settings/keys).
    - Recommended: Reusable, Ephemeral (if you treat containers as cattle), or standard.
    - Tags: `tag:server` (recommended).

2.  **Tailnet Name**: Know your tailnet domain (e.g., `tails-scales.ts.net`).

## Setup Steps

### 1. Prepare Host Directories

Ensure the following directories exist and have the correct permissions.
*   `n8n` runs as UID 1000.
*   `postgres` (Alpine) runs as UID 70.

```bash
# Create directories
sudo mkdir -p /srv/n8n/ts/state
sudo mkdir -p /srv/n8n/ts/config
sudo mkdir -p /srv/n8n/db

# Set permissions
# n8n data directory (UID 1000)
sudo chown -R 1000:1000 /srv/n8n/data

# Postgres data directory (UID 70 for Alpine)
sudo chown -R 70:70 /srv/n8n/db
```

### 2. Update Environment Variables

Edit your `docker/n8n/.env` file (create it if it doesn't exist, based on `.env.example`).

```bash
# docker/n8n/.env

# Your Tailscale Auth Key
TS_AUTHKEY=tskey-auth-xxxxx

# Database Configuration (Postgres)
# Use a strong password!
POSTGRES_USER=n8n
POSTGRES_PASSWORD=mysecretpassword
POSTGRES_DB=n8n

# Your n8n Hostname on Tailscale
# MUST match: <hostname>.<tailnet-name>.ts.net
# Example: If TS_HOSTNAME=n8n and tailnet is example.ts.net, then:
N8N_HOST=n8n.example.ts.net

# Protocol must be https
N8N_PROTOCOL=https

# Webhook URL (used for OAuth callbacks)
WEBHOOK_URL=https://n8n.example.ts.net/

# ... other existing variables ...
```

### 3. Deploy

Run the modified docker-compose stack:

```bash
cd docker/n8n
docker compose up -d
```

### 4. Configure Tailscale Serve (First Run)

Because the `serve.json` config does not exist yet, we need to generate it. The `tailscale-n8n` container will start but might not be serving traffic yet.

1.  **Configure Serve**: Tell Tailscale to listen on HTTPS 443 and proxy to n8n on localhost:5678.

    ```bash
    docker exec tailscale-n8n tailscale serve --https=443 tcp://localhost:5678
    ```
    *Note: We use `localhost` because n8n shares the network namespace.*

2.  **Verify**: Check status.

    ```bash
    docker exec tailscale-n8n tailscale serve status
    ```
    You should see: `https://n8n.example.ts.net (target: tcp://localhost:5678)`

3.  **Persist Configuration**: Export the config to the bind-mounted JSON file.

    ```bash
    docker exec tailscale-n8n tailscale serve status --json > /srv/n8n/ts/config/serve.json
    ```

    Now, if you restart the container, `TS_SERVE_CONFIG=/config/serve.json` will load this configuration automatically.

## Troubleshooting

### HTTPS / Certificate Issues
- **Symptoms**: Browser shows certificate error or "Privacy error".
- **Fix**: 
    - Ensure MagicDNS is enabled in Tailscale Admin Console.
    - Ensure HTTPS Certificates are enabled in Tailscale Admin Console.
    - Wait a minute for the certificate to provision.
    - Check logs: `docker logs tailscale-n8n`.

### OAuth Callbacks failing
- **Symptoms**: Redirecting back from Spotify/Google fails.
- **Fix**:
    - Ensure `WEBHOOK_URL` in `.env` exactly matches the Tailscale HTTPS URL.
    - Ensure `N8N_HOST` matches the Tailscale domain.
    - Verify `N8N_PROTOCOL=https`.

### ACL Blocking
- **Symptoms**: Can't connect even though `tailscale status` is online.
- **Fix**: Check your Tailscale ACLs to ensure your device has access to `tag:server` or the specific n8n host on port 443.
