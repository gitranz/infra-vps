# infra-vps: Infrastructure as Code for a Dockerized VPS

This repository provides infrastructure as code to set up a new Ubuntu VPS, deploy Docker containers for various applications, and manage persistent data with a clear backup strategy.

## Project Structure

```
infra-vps/
  docker/
    n8n/
      docker-compose.yml
      .env.example
    openwebui/
      docker-compose.yml
      .env.example
    proxy/
      docker-compose.yml
      nginx/
        conf.d/...
  scripts/
    bootstrap.sh
    restore-data.sh
  docs/
    README.md
    NOTES.md
```

## Getting Started (New VPS Setup)

This guide assumes you have a fresh Ubuntu server.

1.  **Log in to your new VPS** via SSH.

2.  **Clone this repository** (or your fork) to a suitable location, e.g., your home directory:
    ```bash
    git clone https://github.com/your-repo/infra-vps.git
    cd infra-vps
    ```

3.  **Run the bootstrap script** to install Docker, configure the firewall (UFW), and set up the necessary data directories:
    ```bash
    chmod +x scripts/bootstrap.sh
    ./scripts/bootstrap.sh
    ```
    *Note: The script will add your current user to the `docker` group. You will need to log out and log back in for this change to take effect.*

4.  **Set up AnythingLLM persistent volume permissions (Crucial for AnythingLLM):**
    AnythingLLM's container expects its mounted `/app/server/storage` directory to be owned by `UID=1001` and `GID=1001`. The `bootstrap.sh` script does not set this automatically for new application volumes.
    After running `bootstrap.sh` and before starting AnythingLLM, you must manually set the correct permissions:
    ```bash
    sudo mkdir -p /srv/anythingllm/storage
    sudo chown -R 1001:1001 /srv/anythingllm
    sudo chmod -R 777 /srv/anythingllm/storage
    ```
    This ensures the `anythingllm` container has the necessary read/write access to its persistent storage volume.

5.  **Log out and log back in** to your VPS.

6.  **Configure environment variables:**
    Copy the example environment files and modify them as needed:
    ```bash
    cp docker/n8n/.env.example docker/n8n/.env
    cp docker/openwebui/.env.example docker/openwebui/.env
    # Edit the .env files with your specific settings (e.g., N8N_HOST)
    nano docker/n8n/.env
    nano docker/openwebui/.env
    ```

## Security Setup (Optional but Recommended)

For a new VPS, it is best practice to create a non-root sudo user and disable root login. A helper script is provided:

1.  **Run the security setup script:**
    ```bash
    chmod +x scripts/setup-security.sh
    sudo ./scripts/setup-security.sh
    ```
    This interactive script will:
    *   Create a new user (you specify the name).
    *   Add the user to `sudo` and `docker` groups.
    *   Copy your current root SSH keys to the new user.
    *   (Optionally) Disable root login and password authentication in SSH.

2.  **Verify access:** Open a new terminal and try to SSH in as the new user *before* closing your current session.

## Docker Applications

This setup includes `docker-compose.yml` configurations for the following applications:

## Applications Overview

The following applications are deployed as Docker containers in this infrastructure:

| Application | Docker Image | Version | GitHub Repository |
| :--- | :--- | :--- | :--- |
| **AnythingLLM** | `mintplexlabs/anythingllm` | master | [Mintplex-Labs/anything-llm](https://github.com/Mintplex-Labs/anything-llm) |
| **n8n** | `docker.n8n.io/n8nio/n8n` | 1.122.5 | [n8n-io/n8n](https://github.com/n8n-io/n8n) |
| **Open WebUI** | `ghcr.io/open-webui/open-webui` | main | [open-webui/open-webui](https://github.com/open-webui/open-webui) |
| **Ollama** | `ollama/ollama` | latest | [ollama/ollama](https://github.com/ollama/ollama) |
| **Nginx Proxy Manager** | `jc21/nginx-proxy-manager` | latest | [jc21/nginx-proxy-manager](https://github.com/jc21/nginx-proxy-manager) |
| **VS Code Server** | `lscr.io/linuxserver/code-server` | 4.106.3 | [linuxserver/docker-code-server](https://github.com/linuxserver/docker-code-server) |

## Persistent Data & Backup Candidates

All critical application data is stored in host directories under `/srv`. These are the key locations you should back up to ensure you can fully restore your system.

| Path | Description | Backup Priority |
| :--- | :--- | :--- |
| `/srv/n8n/data` | Stores n8n workflows, credentials, and execution history (SQLite database). | **High** |
| `/srv/ollama/data` | Contains downloaded Large Language Models (LLMs). These can be large but are re-downloadable. | Low (Optional) |
| `/srv/openwebui/data` | Stores user accounts, chat history, and settings for Open WebUI (SQLite database). | **High** |
| `/srv/anythingllm/storage` | Holds AnythingLLM's uploaded documents, vector database, and workspace settings. | **High** |
| `/srv/nginx/data` | Nginx Proxy Manager's database (users, proxy hosts) and configuration. | **High** |
| `/srv/nginx/letsencrypt` | SSL/TLS certificates and renewal configuration. | **High** |
| `/srv/vscode/config` | User settings, installed extensions, and keybindings for VS Code Server. | Medium |

**Note:** Your actual code projects are typically stored in your home directory (e.g., `/home/chrisadmin/workspace`) and mapped into VS Code. Ensure you back up your project files separately (e.g., via Git).

## Backup Strategy

It is CRITICAL to regularly back up the `/srv` directory to a location *not* on this VPS. This ensures your data is safe in case of server failure.

**Recommended Backup Method:** Use `rsync` or a cloud-based backup solution to periodically sync `/srv` to a remote server, object storage (e.g., S3, Backblaze B2), or a dedicated backup service.

Example `rsync` command (run from your backup server):
```bash
# rsync -avh --delete user@your-vps-ip:/srv/ /path/to/your/backup/location/latest/srv/
```

## Restore Ritual (One-Command Restore)

In case of a new VPS setup or data loss, you can restore your application data using the `restore-data.sh` script.

1.  **Ensure your backup data is accessible** on the VPS (e.g., mounted at `/mnt/backup/latest`).

2.  **Run the restore script:**
    ```bash
    chmod +x scripts/restore-data.sh
    ./scripts/restore-data.sh
    ```
    *Note: You will need to uncomment and adjust the `rsync` commands within `restore-data.sh` to match your backup source.*

3.  **Start your Docker containers** after restoration:
    ```bash
    cd docker/n8n && docker compose up -d
    cd ../openwebui && docker compose up -d
    cd ../proxy && docker compose up -d
    cd ../vscode && docker compose up -d
    # Or start all at once if they are in the same directory and you are in infra-vps/docker
    # docker compose -f n8n/docker-compose.yml -f openwebui/docker-compose.yml -f proxy/docker-compose.yml -f vscode/docker-compose.yml up -d
    ```

## Usage

Once the setup is complete and `.env` files are configured, navigate to the respective application's directory and start the Docker containers:

```bash
cd docker/n8n
docker compose up -d

cd ../openwebui
docker compose up -d

cd ../proxy
docker compose up -d

cd ../vscode
# Ensure you have copied .env.example to .env and set secure passwords
cp .env.example .env
nano .env
docker compose up -d
```

To stop them:

```bash
cd docker/n8n
docker compose down
# ...and so on for other applications
```
