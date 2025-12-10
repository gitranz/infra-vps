# Installing Tailscale on VPS Host

This guide documents how to install Tailscale directly on the VPS host (Ubuntu) to enable secure remote access and private networking for Docker services.

## Why Install on the Host?

Installing Tailscale directly on the host OS (instead of a Docker container) is recommended for the following reasons:
1.  **Emergency Access:** If Docker fails, you can still SSH into the host via the Tailscale VPN IP to troubleshoot.
2.  **Simplicity:** No need for special container privileges (`--cap-add=NET_ADMIN`, `/dev/net/tun`).
3.  **Universal Access:** All ports exposed by Docker containers (e.g., Nginx on 80/443) are automatically accessible via the host's Tailscale IP.

## Installation Steps

### 1. Install Tailscale

Run the official installation script:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

### 2. Configure Firewall (UFW)

Allow incoming traffic from the Tailscale network interface (`tailscale0`). This ensures you can access your services over the VPN.

```bash
sudo ufw allow in on tailscale0
sudo ufw reload
```

### 3. Authenticate

Start Tailscale and generate a login URL:

```bash
sudo tailscale up
```

Copy the URL provided in the output and open it in your browser to authenticate and add this machine to your tailnet.

### 4. Verify Connection

Check the status and find your Tailscale IP:

```bash
tailscale status
tailscale ip -4
```

## Accessing Services

Once connected, you can access your Docker services using the VPS's Tailscale IP address.

For example, if your Nginx Proxy Manager is running on port 81:
`http://<TAILSCALE_IP>:81`
