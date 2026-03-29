#!/bin/bash

# --- 0. verify if mpd is installed ---
if ! command -v mpd
then
	echo "mpd could not be found. Installing via pacman..."
	if ! sudo pacman -S --noconfirm mpd
	then
		echo "Error: mpd could not be installed. Exiting."
		exit 1
	fi
fi

# --- 1. set vars ---
# dirs and files
MPD_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/mpd"
MUSIC_DIR="${XDG_MUSIC_DIR:-$HOME/music}"
PLAYLIST_DIR="$MPD_CONF_DIR/playlists"
DB_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/mpd/database"
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/mpd/state"

# where mpd is launched on login
STARTUP_SCRIPT="${XDG_CONFIG_HOME:-$HOME/.config}/startup/startup"

# outputs
BIND_ADDR="127.0.0.1"
PORT_NUM="6600"

# --- 2. create dirs ---
mkdir -p "$MUSIC_DIR"
mkdir -p "$PLAYLIST_DIR"
mkdir -p "$(dirname "$DB_FILE")"
mkdir -p "$(dirname "$STATE_FILE")"

# --- 3. create mpd.conf ---
mkdir -p "$MPD_CONF_DIR"
cat <<EOF > "$MPD_CONF_DIR/mpd.conf"
music_directory    "$MUSIC_DIR"
playlist_directory "$PLAYLIST_DIR"
db_file            "$DB_FILE"
state_file         "$STATE_FILE"

bind_to_address    "$BIND_ADDR"
port               "$PORT_NUM"

audio_output {
	type	"pipewire"
	name	"PipeWire output"
}
EOF

echo "MPD configuration generated at $MPD_CONF_DIR/mpd.conf"

# --- 4. set mpd to autostart ---
mkdir -p "$(dirname "$STARTUP_SCRIPT")"
touch "$STARTUP_SCRIPT"

if ! grep -q "^mpd &" "$STARTUP_SCRIPT"; then
	# ensure there's a newline before appending if not empty
	[ -s "$STARTUP_SCRIPT" ] && echo "" >> "$STARTUP_SCRIPT"

	echo "mpd &" >> "$STARTUP_SCRIPT"
	chmod +x "$STARTUP_SCRIPT"
	echo "mpd added to startup script at $STARTUP_SCRIPT"
fi

# finish
echo "mpd setup script finished!"
