#!/usr/bin/env bash
# ============================================================================
# This shell script is to deploy my i3 configuration and work environment
# ============================================================================

# ----------------------------------------------------------------------------
# Environment variables
# ----------------------------------------------------------------------------
# Add following lines to ~/.profile
profile="$HOME/.profile"
export PATH=$HOME/.config/i3/script:$PATH >> $profile
cat 'export I3_SCRIPT=$HOME/.config/i3/script' >> $profile

# ----------------------------------------------------------------------------
# Link config directories to $HOME/.config/*
# ----------------------------------------------------------------------------
# Link/copy config directories/files under ~/.config
user_config_dir="$HOME/.config"
new_config_dir="$HOME/Desktop/I3_Sway_Config/config"
user_config_backup="$HOME/.config_backup"
user_config_list=(cava conky dunst i3 kitty ncspot \
                  neofetch picom ranger rofi spotify-tui \
                  zathura vis bumblebee-status)
mkdir $user_config_backup
for config in ${user_config_list[@]};
do
    mv $user_config_dir/$config $user_config_backup
    ln -s $new_config_dir/$config $user_config_dir/$config
done

# ----------------------------------------------------------------------------
# TODO: Script to install needed packages
# ----------------------------------------------------------------------------
# Packages needed for my i3 work environment

# Python packages
#pip install bumblebee-status autotiling pywal

# Fedora packages
#dnf install kitty dunst rofi conky neofetch
