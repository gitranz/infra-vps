#!/bin/bash
set -e

echo "Starting data restoration..."

# IMPORTANT: Replace with your actual backup source and method.
# This script assumes you have a backup of your /srv data.
# For example, if your backups are in /mnt/backup/latest/srv:

# Restore n8n data
# sudo rsync -avh /mnt/backup/latest/srv/n8n/data/ /srv/n8n/data/

# Restore ollama data (if applicable)
# sudo rsync -avh /mnt/backup/latest/srv/ollama/data/ /srv/ollama/data/

# Restore openwebui data
# sudo rsync -avh /mnt/backup/latest/srv/openwebui/data/ /srv/openwebui/data/

# Restore nginx data and letsencrypt certificates
# sudo rsync -avh /mnt/backup/latest/srv/nginx/data/ /srv/nginx/data/
# sudo rsync -avh /mnt/backup/latest/srv/nginx/letsencrypt/ /srv/nginx/letsencrypt/

echo "Data restoration script complete. Please start your Docker containers afterwards."
