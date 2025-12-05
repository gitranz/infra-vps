#!/bin/bash
set -e

echo "Creating /srv directories..."
sudo mkdir -p /srv/n8n/data
sudo mkdir -p /srv/ollama/data
sudo mkdir -p /srv/openwebui/data
sudo mkdir -p /srv/nginx/data
sudo mkdir -p /srv/nginx/letsencrypt

echo "Migrating Nginx Proxy Manager data from $HOME/nginx_proxymanager..."
if [ -d "$HOME/nginx_proxymanager/data" ]; then
  sudo cp -r "$HOME/nginx_proxymanager/data/." /srv/nginx/data/
fi
if [ -d "$HOME/nginx_proxymanager/letsencrypt" ]; then
  sudo cp -r "$HOME/nginx_proxymanager/letsencrypt/." /srv/nginx/letsencrypt/
fi

echo "Migrating Docker Named Volumes to /srv..."
echo "Note: This uses a temporary Alpine container to copy data from the volume to the host."

echo "Migrating n8n_data..."
# Check if volume exists
if docker volume inspect n8n_data > /dev/null 2>&1; then
    docker run --rm -v n8n_data:/from -v /srv/n8n/data:/to alpine sh -c "cp -av /from/. /to/"
else
    echo "Volume n8n_data not found, skipping."
fi

echo "Migrating openwebui_ollama..."
if docker volume inspect openwebui_ollama > /dev/null 2>&1; then
    docker run --rm -v openwebui_ollama:/from -v /srv/ollama/data:/to alpine sh -c "cp -av /from/. /to/"
else
    echo "Volume openwebui_ollama not found, skipping."
fi

echo "Migrating openwebui_open-webui..."
if docker volume inspect openwebui_open-webui > /dev/null 2>&1; then
    docker run --rm -v openwebui_open-webui:/from -v /srv/openwebui/data:/to alpine sh -c "cp -av /from/. /to/"
else
    echo "Volume openwebui_open-webui not found, skipping."
fi

echo "Migration complete. Your data is now in /srv."
echo "You can now start the new stacks using the docker compose files in infra-vps/docker/"
