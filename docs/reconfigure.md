# Reconfiguring Services for Tailscale-Only Access

This guide details how to transition your Docker services from a public-facing Nginx reverse proxy setup to a secure, private setup accessible only via your Tailscale network.

## Current State Analysis
- **Old Setup:** Nginx Proxy Manager (on ports 80/443) routed traffic to containers (n8n, khoj, etc.) which were often bound only to `127.0.0.1` or hidden inside a Docker network.
- **New Setup:** Ports 80/443 are closed firewall-side. You want to access services directly using your Tailscale IP address or DNS name.

## Strategy
1.  **Decommission the Proxy:** We will stop the Nginx Proxy Manager as it is no longer the entry point.
2.  **Expose Services to Tailscale:** We will modify each service's `docker-compose.yml` to:
    -   Remove the dependency on the `nginx_proxymanager_default` network.
    -   Bind ports to `0.0.0.0` (all interfaces) or your Tailscale IP, instead of `127.0.0.1` (localhost only).
3.  **Access:** You will access services via `http://<TAILSCALE_IP>:<PORT>`.

---

## Step-by-Step Instructions

### 1. Stop the Nginx Proxy
Since we are closing public ports, this service is no longer needed for routing.

```bash
cd ~/workspace/infra-vps/docker/proxy
docker-compose down
```
*Note: This will remove the `nginx_proxymanager_default` network. Your other containers will likely need to be restarted after config changes.*

### 2. Reconfigure Individual Services

For each service below, you need to edit its `docker-compose.yml`.

#### A. n8n
**File:** `docker/n8n/docker-compose.yml`

*   **Network:** Remove the `networks` section referencing `nginx_proxymanager_default`.
*   **Ports:** Change `127.0.0.1:5678:5678` to `5678:5678`.

**Configuration to change:**
```yaml
ports:
  - "5678:5678"  # Changed from 127.0.0.1:5678:5678
# networks:      # Remove or comment out
#   - nginx_proxymanager_default
```

#### B. Khoj
**File:** `docker/khoj/docker-compose.yml`

*   **Network:** Remove `nginx_proxymanager_default` from `networks`.
*   **Ports:**
    *   Server: Change `127.0.0.1:42110:42110` to `42110:42110`.
    *   Computer (optional): Change `127.0.0.1:5900:5900` to `5900:5900`.

**Configuration to change:**
```yaml
services:
  server:
    ports:
      - "42110:42110" # Changed from 127.0.0.1:42110:42110
    # ...
    # networks:
    #   - nginx_proxymanager_default
```

#### C. AnythingLLM
**File:** `docker/anything-llm/docker-compose.yml`

*   **Network:** Remove `nginx_proxymanager_default`.
*   **Ports:** It is already `3001:3001`, which is correct.

#### D. VS Code Server
**File:** `docker/vscode/docker-compose.yml`

*   **Network:** Remove `nginx_proxymanager_default`.
*   **Ports:** It is already `8443:8443`, which is correct.

#### E. OpenWebUI
**File:** `docker/openwebui/docker-compose.yml`

*   **Ports:** It uses `${OPENWEBUI_PORT}:8080`. Ensure `OPENWEBUI_PORT` is set in your `.env` file (e.g., to 3000 or 8080).
*   **Network:** It uses the default network, so no network changes are strictly needed, but verify it doesn't depend on the proxy for anything else.

### 3. Apply Changes & Restart
After editing the files, restart each service to apply the new networking rules.

```bash
# Example for n8n
cd ~/workspace/infra-vps/docker/n8n
docker-compose down && docker-compose up -d

# Repeat for other folders...
```

### 4. Verify Access
Get your Tailscale IP:
```bash
tailscale ip -4
# Example output: 100.x.y.z
```

Now you can access your apps from any device on your Tailscale network:
- **n8n:** `http://100.x.y.z:5678`
- **Khoj:** `http://100.x.y.z:42110`
- **AnythingLLM:** `http://100.x.y.z:3001`
- **VS Code:** `https://100.x.y.z:8443` (VS Code often enforces HTTPS or handles its own auth)

---

## Advanced Option: "Tailscale Serve" (Pretty URLs)

If you don't want to remember ports, you can use **Tailscale Serve** to map a DNS name to a local port.

**Example for n8n:**
Run this command on your VPS:
```bash
sudo tailscale serve --bg 5678
```
This will make n8n available at `https://<your-machine-name>.<tailnet-name>.ts.net`.

To serve multiple apps, you might need to use "Funnel" or configure specific paths, but the simplest way for multiple apps is sticking to ports or using MagicDNS names if you run `tailscale` *inside* containers (Sidecar pattern), which is more complex.

For now, **Step 2 (Direct Port Access)** is the most robust and simplest method given your current setup.
