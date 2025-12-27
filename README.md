# Kerb's Auto-Rice Bootstrapping Scripts (KARBS)
*Work in Progress*

## Installation:

```
git clone https://github.com/kerbilliam/karbs.git
cd karbs
sudo sh karbs.sh
```

That's it.

## What is KARBS?

KARBS is a collection of scripts that installs packages and sets up a
simple and effective Arch Linux environment that I
personally use.

By itself, KARBS sets up an environment using sway, a wayland based window manager, and uses 
my own configuration files from [konf](https://github.com/kerbilliam/konf).
However, it is very easy to change the packages that KARBS
installs by editing `progs.txt` and the location of the configuration files within `karbs.sh`.



## Customization

By default, KARBS uses the programs [here in progs.txt](progs.txt) and installs
[my dotfiles repo (konf)](https://github.com/kerbilliam/konf),
but you can easily change this by either modifying the default variables at the
beginning of the script or editing the programs in progs.txt.

### The `progs.txt` list

KARBS will parse the given programs list and install all given programs. Note
that the line containing the program has at least two columns.

The first column is a "tag" that determines how the program is installed, 's'
for the main repository, `a` for via the AUR.

The second column is the name of the program in the repository.

It is possible to add descriptions after the program name; they just
need to be separated by a space from the program name.

### The `hooks` directory

The `hooks` directory contains all the pacman hooks that KARBS will copy
over to `/etc/pacman.d/hooks. Feel free do add more if desired.

### The `interception` directory

The `interception` directory contains configuration files needed by a program
called interception to rebind the capslock key to function as a esc when tapped
and the super key when held down.

## What inspired KARBS?

My goal was to build a similar environment to Luke Smith's [LARBS](https://github.com/LukeSmithxyz/LARBS)
which is minimal and vim-based. I originally attempted to create a clone of LARBS with dwl and wayland,
but I found out that it is highly unstable and many of the patches are simply outdated. Therefore,
I decided to use sway instead and build my own personal setup from the ground-up while taking heavy
inspiration from LARBS.
