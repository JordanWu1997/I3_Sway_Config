#!/usr/bin/env fish

# i3 version
echo "### i3 ###"
i3 --version
echo

# i3bar version
echo "### i3bar ###"
i3bar --version
echo

# bumblebee-status version
echo "### bumblebee-status ###"
pip show bumblebee-status | grep Version
echo

# kitty version
echo "### kitty ###"
kitty --version
echo

# fish version
echo "### fish ###"
fish --version
echo

# oh-my-fish version
echo "### oh-my-fish ###"
omf --version
echo

# starship version
echo "### starship ###"
starship --version
echo

# tmux version
echo "### tmux ###"
tmux -V
echo

# neovim version
echo "### neovim ###"
nvim --version
echo

# rofi version
echo "### rofi ###"
rofi -version
echo

# wal version
echo "### wal ###"
wal -v
echo

# picom version
echo "### picom ###"
picom --version
echo

# dunst version
echo "### dunst ###"
dunst --version
echo

# ranger version
echo "### ranger ###"
ranger --version
echo
