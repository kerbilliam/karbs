#!/bin/bash

check_deps() {
	local missing_deps=()
	for tool in "$@"; do
		if ! command -v "$tool" >/dev/null 2>&1; then
			missing_deps+=("$tool")
		fi
	done

	if [ ${#missing_deps[@]} -ne 0 ]; then
		echo "The following dependencies are missing: ${missing_deps[*]}"
		read -p "Would you like to install them via pacman? [y/N]: " install_confirm
		if [[ "$install_confirm" =~ ^[Yy]$ ]]; then
			sudo pacman -S --noconfirm "${missing_deps[@]}"
		else
			echo "Exiting. Please install dependencies manually."
			exit 1
		fi
	fi
}

# --- checking deps ---
check_deps git gpg pinentry

# Ensure GNUPGHOME is set; fallback to default if not
: "${GNUPGHOME:=$HOME/.gnupg}"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

# Function to generate a new SSH key
generate_ssh_key() {
    read -rp "Enter your email for the SSH key: " email
    ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519"
    echo "SSH key generated at $HOME/.ssh/id_ed25519"
}

# Check for existing keys
# --- 3. SSH Key Handling ---
SH_KEYS=()
for key in "$HOME"/.ssh/id_{rsa,ed25519,ecdsa}; do
    if [[ -f "$key" && ! "$key" =~ \.pub$ ]]; then
        SH_KEYS+=("$key")
    fi
done

if [ ${#SH_KEYS[@]} -eq 0 ]; then
    echo "No SSH private keys found in $HOME/.ssh/"
    echo "1) Exit to add keys manually"
    echo "2) Generate a new Ed25519 key now"
    echo "3) Continue anyway (not recommended)"
    read -p "Select an option [1-3]: " opt
    
    case $opt in
        1) echo "Exiting..."; exit 1 ;;
        2) generate_ssh_key ;;
        3) echo "Continuing..." ;;
        *) echo "Invalid option. Exiting..."; exit 1 ;;
    esac
fi

echo "--- Configuring gpg-agent for SSH emulation ---"

# 1. Setup gpg-agent.conf
cat > "$GNUPGHOME/gpg-agent.conf" <<EOF
enable-ssh-support
default-cache-ttl 7200
max-cache-ttl 28800
pinentry-program /usr/bin/pinentry-qt
EOF

# 2. Start/Restart the agent
gpgconf --kill gpg-agent
gpg-connect-agent /bye > /dev/null 2>&1

# 3. Link SSH keys to GPG (sshcontrol)
# Use ssh-add to "register" them with the running gpg-agent
echo "--- Linking SSH keys to GPG (sshcontrol) ---"
for key in $HOME/.ssh/id_{rsa,ed25519,ecdsa}; do
    if [ -f "$key" ]; then
        # This tells gpg-agent to take control of this key
        # On Arch, this automatically updates ~/.gnupg/sshcontrol
        SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket) ssh-add "$key"
        echo "Linked $key to gpg-agent."
    fi
done

# 4. Global Git Signing Config
echo "--- Configuring Git for automatic signing ---"
git config --global commit.gpgsign true
git config --global gpg.program gpg

echo "--- Done! ---"
echo "Note: If you haven't yet, you must set your Git signing key:"
echo "git config --global user.signingkey <YOUR_GPG_KEY_ID>"
