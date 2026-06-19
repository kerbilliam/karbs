#!/bin/bash

pacman -Syu --noconfirm --needed noto-fonts-cjk

if ! locale -a | grep -x ja_JP.utf8; then
	sed -i /etc/locale.gen 's/#ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/'
	locale-gen
fi

pacman -Syu --noconfirm --needed fcitx5-im fcitx5-mozc

export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx

cat <<EOF >> ~/.zprofile
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
EOF
