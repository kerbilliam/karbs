#!/bin/sh

# Kerb's Auto Rice Bootstrapping Script (KARBS)
# Heavily Inspired by Luke Smith's LARBS at https://github.com/LukeSmithxyz/LARBS
# License: GNU GPLv3

### OPTIONS AND VARIABLES ###

# Location of dotfiles archive (.tar.gz). Leave empty if not a url.
dotfiles="https://github.com/kerbilliam/konf/archive/refs/heads/master.tar.gz"

# Location of the program list. Can be a url [http(s)] or file on system.
progsfile="./progs.txt"

# Location of the directory for the config files required for remapping capslock.
interceptiondir="./interception"

# Location of directoy containing pacman hooks
hooksdir="./hooks"

export TERM=ansi
RED=$(tput setaf 1)
GRN=$(tput setaf 2)
YLL=$(tput setaf 3)
RST=$(tput sgr0)

### FUNCTIONS ###

redout() {
	echo "${RED}$1${RST}"
}

greenout() {
	echo "${GRN}$1${RST}"
}

yellowout() {
	echo "${YLL}$1${RST}"
}

installpkg() {
	pacman --noconfirm --needed -S "$@"
}

error() {
	# Log to stderr and exit with failure.
	printf "${RED}%s${RST}\n" "$1" >&2
	exit 1
}

manualinstall() {
	# Installs $1 manually. Used only for AUR helper here.
	# Should be run after repodir is created and var is set.
	pacman -Qq "$1" && return 0
	echo "$1 manually."
	sudo -u "$user" mkdir -p "$repodir/$1"
	sudo -u "$user" git -C "$repodir" clone --depth 1 --single-branch \
		--no-tags -q "https://aur.archlinux.org/$1.git" "$repodir/$1" ||
		{
			cd "$repodir/$1" || return 1
			sudo -u "$user" git pull --force origin master
		}
	cd "$repodir/$1" || exit 1
	sudo -u "$user" \
		makepkg --noconfirm -si >/dev/null 2>&1 || return 1
}

### THE ACTUAL SCRIPT ###

[ "$(id -u)" -ne 0 ] && error "You need to run this script as a root."

# User confirmation
printf "Which user are you running KARBS for? "
read -r user
if grep ^"$user" /etc/passwd; then
	greenout 'User found!'
else
	error 'User not found!'
fi
yellowout "Make sure the user has a home folder in the output above."
echo "By proceeding, no further input from the user is required."
printf "Confirm you want to continue with the installation for user %s. (y)Yes/(n)No: " "$user"
read -r choice
case $choice in
	[yY]* ) greenout "Proceeding to install KARBS..." ;;
	[nN]* ) error 'User exited.' ;;
	*) error 'Invalid input. Installation cancelled.' ;;
esac

# Install required packages for script.
pacman --noconfirm --needed -Sy curl \
	ca-certificates base-devel git zsh dash \
	interception-tools interception-dual-function-keys ||
	error "Failed to install required packages for the script."


# Make pacman colorful and use concurrent downloads.
sed -Ei "s/^#(ParallelDownloads).*/\1 = 5/;/^#Color$/s/#//" /etc/pacman.conf

# Use all cores for compilation.
sed -i "s/-j2/-j$(nproc)/;/^#MAKEFLAGS/s/^#//" /etc/makepkg.conf

[ -f /etc/sudoers.pacnew ] && cp /etc/sudoers.pacnew /etc/sudoers # Just in case

# Allow user to run sudo without password. Since AUR programs must be installed
# in a fakeroot environment, this is required for all builds with AUR.
trap 'rm -f /etc/sudoers.d/karbs-temp' HUP INT QUIT TERM PWR EXIT
echo "%wheel ALL=(ALL) NOPASSWD: ALL
Defaults:%wheel,root runcwd=*" >/etc/sudoers.d/karbs-temp

# Install Standard Packages
awk '$1== "s"{print $2}' "$progsfile" | xargs pacman --noconfirm --needed -Syu ||
	error "Failed to install standard packages. Exiting..."

# Install AUR Helper: yay and install AUR packages
repodir="/home/$user/.local/src"
sudo -u "$user" mkdir -p "$repodir"
chown -R "$user":wheel "$(dirname "$repodir")"
manualinstall yay-bin || error "Failed to install AUR helper."
awk '$1== "a"{print $2}' "$progsfile" | xargs sudo "$user" yay -S --noconfirm

# Make sure .*-git AUR packages get updated automatically.
sudo -u "$user" yay -Y --save --devel

# Install the dotfiles in the user's home directory.
# --strip-components is to remove the wrapper directory by github.
# Also remove extra READMEs and the such.
if [ -f "$dotfiles" ]; then
    sudo -u "$user" tar -xzf "$dotfiles" --overwrite -C /home/"$user"/
else
    "$user" curl -Ls "$dotfiles" |
	sudo -u "$user" tar xzf - --strip-components=1 --overwrite -C /home/"$user"/
fi
rm -rf "/home/$user/README.md" "/home/$user/LICENSE"

# Make zsh the default shell for the user.
chsh -s /bin/zsh "$user" >/dev/null 2>&1
sudo -u "$user" mkdir -p "/home/$user/.cache/zsh/"

# Create a playlists directory for MPD
sudo -u "$user" mkdir -p "/home/$user/.config/mpd/playlists/"

# Create pacman hooks directory
mkdir -p /etc/pacman.d/hooks

# Make dash the default #!/bin/sh symlink.
ln -sfT dash /usr/bin/sh

# Rebind capslock
cp -rv "$interceptiondir" /etc/
systemctl enable udevmon

# copy pacman hooks
cp -rv "$hooksdir"/* /etc/pacman.d/hooks/

# Cleanup
rm -f /etc/sudoers.d/karbs-temp

# Last message! Install complete!
greenout 'KARBS installation complete. Please restart your system to start using KARBS. Have fun!'
