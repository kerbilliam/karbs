#!/usr/bin/env bash

GPGHOME=${GNUPGHOME:-$HOME/.gnupg}

# --- 1. Install Dependencies ---
echo "Installing GPG and Pinentry tools..."
sudo pacman -S --needed gnupg pinentry git

# --- 2. Configure GPG Agent ---
echo "Configuring gpg-agent..."
mkdir -p "$GPGHOME"
chmod 700 "$GPGHOME" # make safer permissions

cat <<EOF > "$GPGHOME/gpg-agent.conf"
enable-ssh-support
default-cache-ttl 3600
max-cache-ttl 28800
default-cache-ttl-ssh 3600
max-cache-ttl-ssh 28800
pinentry-program /usr/bin/pinentry-qt
EOF

# --- 3. Setup Systemd Socket Activation ---
echo "Enabling GPG Agent sockets..."
systemctl --user enable --now gpg-agent.socket
systemctl --user enable --now gpg-agent-ssh.socket

# --- 4. Handle the SSH Key ---
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
    echo "No SSH key found. Generating a new one..."
    echo "Note: If you are using this key to connect to GitHub, it must be the same as your GitHub eamil address."
    read -r -p "Enter email for key: " email
    ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519"
fi

# --- 5. Update .ssh/config ---
mkdir -p ~/.ssh
chmod 700 ~/.ssh
if [[ ! -f "$HOME/.ssh/config" ]] || ! grep -q "AddKeysToAgent" "$HOME/.ssh/config"; then
    cat <<EOF >> "$HOME/.ssh/config"

Host *
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519
EOF
    chmod 600 "$HOME/.ssh/config"
fi

echo "-------------------------------------------------------"
echo "GPG SSH SETUP COMPLETE"
echo "-------------------------------------------------------"
