#!/bin/bash
set -e

# Warning: This script modifies SSH configuration and creates users.
# Run this as root (or with sudo) on a fresh VPS.

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

read -p "Enter the new username to create: " NEW_USER

if id "$NEW_USER" &>/dev/null; then
    echo "User $NEW_USER already exists."
else
    # Create user with home directory and bash shell
    useradd -m -s /bin/bash "$NEW_USER"
    echo "User $NEW_USER created."
    
    # Set password
    echo "Please set a password for $NEW_USER:"
    passwd "$NEW_USER"
fi

# Add to sudo group
usermod -aG sudo "$NEW_USER"
echo "Added $NEW_USER to sudo group."

# Add to docker group (if it exists)
if getent group docker > /dev/null; then
    usermod -aG docker "$NEW_USER"
    echo "Added $NEW_USER to docker group."
fi

# Setup SSH for the new user
mkdir -p /home/"$NEW_USER"/.ssh
chmod 700 /home/"$NEW_USER"/.ssh

# Copy root's authorized_keys to the new user if it exists
if [ -f /root/.ssh/authorized_keys ]; then
    echo "Copying /root/.ssh/authorized_keys to /home/$NEW_USER/.ssh/..."
    cp /root/.ssh/authorized_keys /home/"$NEW_USER"/.ssh/authorized_keys
    chmod 600 /home/"$NEW_USER"/.ssh/authorized_keys
    chown -R "$NEW_USER":"$NEW_USER" /home/"$NEW_USER"/.ssh
    echo "SSH keys copied. You can now login as $NEW_USER with your existing key."
else
    echo "WARNING: /root/.ssh/authorized_keys not found. You may need to manually add your public key to /home/$NEW_USER/.ssh/authorized_keys before logging in."
fi

# SSH Security Hardening
read -p "Do you want to disable root login and password authentication for SSH? (y/n) " HARDEN_SSH

if [[ "$HARDEN_SSH" =~ ^[Yy]$ ]]; then
    SSH_CONFIG="/etc/ssh/sshd_config"
    
    # Backup config
    cp "$SSH_CONFIG" "$SSH_CONFIG.bak"
    
    # Disable Root Login
    if grep -q "^PermitRootLogin" "$SSH_CONFIG"; then
        sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
    else
        echo "PermitRootLogin no" >> "$SSH_CONFIG"
    fi
    
    # Disable Password Authentication
    if grep -q "^PasswordAuthentication" "$SSH_CONFIG"; then
        sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
    else
        echo "PasswordAuthentication no" >> "$SSH_CONFIG"
    fi
    
    # Disable Empty Passwords (good practice)
    if grep -q "^PermitEmptyPasswords" "$SSH_CONFIG"; then
        sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$SSH_CONFIG"
    else
        echo "PermitEmptyPasswords no" >> "$SSH_CONFIG"
    fi

    # Restart SSH service
    if systemctl is-active --quiet ssh; then
        systemctl restart ssh
        echo "SSH configuration updated and service restarted."
    elif systemctl is-active --quiet sshd; then
        systemctl restart sshd
         echo "SSH configuration updated and service restarted."
    else
         echo "WARNING: Could not restart SSH service. Please restart it manually."
    fi
    
    echo "Security hardening complete: Root login disabled, Password auth disabled."
else
    echo "Skipping SSH hardening."
fi

echo "Setup complete!"
echo "IMPORTANT: Open a NEW terminal window and try to SSH as $NEW_USER BEFORE closing this session to ensure you are not locked out."
