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
echo 'export I3_SCRIPT=$HOME/.config/i3/script' >> $profile

# ----------------------------------------------------------------------------
# Link config directories to $HOME/.config/*
# ----------------------------------------------------------------------------
# Link/copy config directories/files under ~/.config
USER_CONFIG_DIR="$HOME/.config"
NEW_CONFIG_DIR="$HOME/Desktop/I3_Sway_Config/config"
USER_CONFIG_BACkUP="$HOME/.config_backup"
USER_CONFIG_LIST=(cava conky dunst i3 kitty ncspot \
                  neofetch picom ranger rofi spotify-tui \
                  zathura vis bumblebee-status flashfocus)
mkdir $USER_CONFIG_BACKUP
for config in ${USER_CONFIG_LIST[@]};
do
    mv $USER_CONFIG_DIR/$config $USER_CONFIG_BACKUP
    ln -s $NEW_CONFIG_DIR/$config $USER_CONFIG_DIR/$config
done

# ----------------------------------------------------------------------------
# TODO: Script to install needed packages
# ----------------------------------------------------------------------------
# Packages needed for my i3 work environment

# Python packages
#pip install bumblebee-status autotiling pywal

# Fedora packages
#dnf install kitty dunst rofi conky neofetch
