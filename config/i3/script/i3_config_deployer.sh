#!/usr/bin/env bash
# ============================================================================
# This shell script is to deploy my i3 configuration and work environment
# ============================================================================

# ----------------------------------------------------------------------------
# Part 0 - Instruction
# ----------------------------------------------------------------------------
case $1 in
    "link")
        ;;
    "copy")
        ;;
    *)
        echo
        echo "Wrong input: $0"
        echo "Usage: ./i3_config_deployer.sh [options]"
        echo "Available option: link/copy"
        echo
        exit
        ;;
esac

# ----------------------------------------------------------------------------
# Part 1 - Environment variables
# ----------------------------------------------------------------------------
# Add following lines to ~/.profile
PROFILE="$HOME/.profile"

echo ''                                           >> $PROFILE
echo '# ========== I3WM Environments ===========' >> $PROFILE
echo 'export I3_SCRIPT=""$HOME/.config/i3/script' >> $PROFILE
echo 'export PATH="$I3_SCRIPT:$PATH"'             >> $PROFILE
echo '# ========================================' >> $PROFILE
echo ''                                           >> $PROFILE

# ----------------------------------------------------------------------------
# Part 2 - Link config directories to $HOME/.config/*
# ----------------------------------------------------------------------------
# Link/copy config directories/files under ~/.config
USER_CONFIG_DIR="$HOME/.config"
NEW_CONFIG_DIR="$HOME/Desktop/I3_Sway_Config/config"
USER_CONFIG_BACKUP="$HOME/.config_backup"
USER_CONFIG_LIST=(bumblebee-status cava conky dunst flashfocus glow i3 kitty \
                  libinput-gestures.conf ncspot neofetch picom ranger rofi \
                  spotify-tui vis zathura)

mkdir $USER_CONFIG_BACKUP
for config in ${USER_CONFIG_LIST[@]};
do
    mv $USER_CONFIG_DIR/$config $USER_CONFIG_BACKUP
    case $1 in
        "link")
            ln -s $NEW_CONFIG_DIR/$config $USER_CONFIG_DIR/$config
            ;;
        "copy")
            cp -fr $NEW_CONFIG_DIR/$config $USER_CONFIG_DIR/$config
            ;;
    esac
done

# ----------------------------------------------------------------------------
# Part 3 - Script to install needed packages
# ----------------------------------------------------------------------------
# Packages needed for my i3 work environment

##################
# Shell packages #
##################

# Terminal emulator, shell tools and etc.
sudo dnf install kitty gnome-terminal fish tmux git

################
# Input method #
################

# Ibus input
sudo dnf install ibus ibus-chewing

################
# X-compositor #
################

# Picom [https://github.com/jonaburg/picom]
sudo dnf install meson gcc ninja-build cmake libev-devel xcb-util-devel \
                 libX11-devel xcb-util-renderutil-devel xcb-util-image \
                 xcb-util-image-devel xcb-util-renderutil-devel pixman-devel \
                 uthash-devel libconfig-devel pcre-devel mesa-libGL-devel \
                 dbus-devel libXext-devel
cd $HOME/Desktop
git clone https://github.com/jonaburg/picom.git
cd picom
git submodule update --init --recursive
meson --buildtype=release . build
sudo ninja -C build

##################
# X-window tools #
##################

# X-window tools
sudo dnf install xrandr arandr imwheel xdotool xset numlockx libinput \
                 xbacklight i3lock xss-lock screenkey flameshot feh redshift

# hhpc
cd $HOME/Desktop
git clone https://github.com/aktau/hhpc.git
cd hhpc
sudo make

###############
# Audio tools #
###############

# Audio controls
sudo dnf install pavucontrol pulseaudio
python -m pip install pulsemixer

# Cava/Vis [https://github.com/dpayne/cli-visualizer]
sudo dnf install cava
dnf install fftw-devel ncurses-devel pulseaudio-libs-devel cmake
cd $HOME/Desktop
git clone https://github.com/dpayne/cli-visualizer.git
cd cli-visualizer
sudo ./install.sh

#######################
# Radio/Network tools #
#######################

# Bluetooth, network manager
sudo dnf install blueman NetworkManager

###################
# Gnome softwares #
###################

# File browser, network browser, and etc.
sudo dnf install nautilus firefox brave-browser gnome-screenshot \
                 polkit-gnome variety

##########
# i3-gap #
##########

# i3 gap
sudo dnf copr enable fuhrmann/i3-gaps
sudo dnf install i3-gaps

# i3 tools
python -m pip install autotiling pywal flashfocus i3-workspace-swap i3-resurrect
sudo dnf install dunst rofi

##########
# i3-bar #
##########

# Bumblebee-status [https://github.com/tobi-wan-kenobi/bumblebee-status]
cd $HOME/Desktop
python -m pip install bumblebee-status i3ipc utils
sudo dnf install python-netifaces lm_sensors pulseaudio-utils

#########
# Theme #
#########

# Theme configurator and fonts
cd $HOME/Desktop
sudo dnf install gtk-chtheme lxappearance qt-config qt5ct qt5-qtstyleplugins \
                 kvantum arc-theme papirus-icon-theme
mkdir -p $HOME/.local/share/fonts
cd $HOME/.local/share/fonts
curl -fLo "Droid Sans Mono for Powerline Nerd Font Complete.otf" "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete.otf"

################
# Editor tools #
################

# Text editor tools
sudo dnf install neovim parcellite

# Ranger [https://github.com/ranger/ranger]
cd $HOME/Desktop
sudo dnf install ranger w3m w3m-img
git clone https://github.com/alexanderjeurissen/ranger_devicons.git ~/.config/ranger/plugins/ranger_devicons

# Glow [https://github.com/charmbracelet/glow]
cd $HOME/Desktop
git clone https://github.com/charmbracelet/glow.git
cd glow
sudo go build

# Zathura-pywal [https://github.com/mlscarlson/zathura-pywal]
cd $HOME/Desktop
sudo dnf install zathura okular
git clone https://github.com/mlscarlson/zathura-pywal.git
cd zathura-pywal
sudo make install
