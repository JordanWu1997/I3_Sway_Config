#!/usr/bin/env bash
# ============================================================================
# This shell script is to distribute my i3 configuration and work environment
# ============================================================================

# ----------------------------------------------------------------------------
# Section 1 - Environment variables
# ----------------------------------------------------------------------------

# Add following lines to ~/.profile
PROFILE="$HOME/.profile"

add_enviroment_variables () {
    echo ''                                               >> $PROFILE
    echo '# =========== I3_SCRIPT Variables ============' >> $PROFILE
    echo 'export I3_SCRIPT=""$HOME/.config/i3/script'     >> $PROFILE
    echo '# ============================================' >> $PROFILE
    echo ''                                               >> $PROFILE
    echo '# ============ I3_SHARE Variables ============' >> $PROFILE
    echo 'export WALLPAPERI3="$HOME/.config/i3/share"'    >> $PROFILE
    echo '# ============================================' >> $PROFILE
    echo ''                                               >> $PROFILE
    echo '# ============ I3WM Environments =============' >> $PROFILE
    echo 'export PATH="$I3_SCRIPT:$PATH"'                 >> $PROFILE
    echo '# ============================================' >> $PROFILE
    echo ''                                               >> $PROFILE
}

section1_greetings () {
    echo
    echo '# ============ Section 1 - Environment Variable ============= #'
    echo '# This section is to add enviroment variable to shell profile #'
    echo '# =========================================================== #'
    echo
}

section1_greetings
echo "Do you want to add enviroment variables (e.g. \$path) to $PROFILE ?"
select option in \
    'yes' \
    'no'
do
    case $option in
        'yes')
            add_enviroment_variables
            echo "Environment variables are added to $PROFILE ..."
            break
            ;;
        'no')
            echo "Adding environment variables is ignored ..."
            break
            ;;
    esac
done

# ----------------------------------------------------------------------------
# Section 2 - Link config directories to $HOME/.config/*
# ----------------------------------------------------------------------------
# Link/copy config directories/files under ~/.config
NEW_CONFIG_DIR="$HOME/Desktop/I3_Sway_Config/config"
USER_CONFIG_DIR="$HOME/.config"
USER_CONFIG_BACKUP="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
USER_CONFIG_LIST=( bumblebee-status cava conky dunst flashfocus glow i3 kitty \
                   libinput-gestures.conf ncspot neofetch picom ranger rofi \
                   spotify-tui vis zathura )

section2_greetings () {
    echo
    echo '# ========== Section 2 - Configuration ========== #'
    echo '# This section is to copy/link configuration file #'
    echo '# =============================================== #'
    echo
}

section2_greetings
echo "What do you want to do with local configuration files ($USER_CONFIG_DIR)?"
select option in \
    'link' \
    'copy' \
    'pass'
do
    case $option in
        'link')
            mkdir $USER_CONFIG_BACKUP
            for config in ${USER_CONFIG_LIST[@]}
            do
                mv $USER_CONFIG_DIR/$config $USER_CONFIG_BACKUP/
                #echo "ln -s $NEW_CONFIG_DIR/$config $USER_CONFIG_DIR"
                /usr/bin/ln -s $NEW_CONFIG_DIR/$config $USER_CONFIG_DIR
                echo "$USER_CONFIG_DIR/$config linked ..."
            done
            echo "Linking configuration done ..."
            echo "Old local configuration files have been moved to $USER_CONFIG_BACKUP"
            break
            ;;
        'copy')
            mkdir $USER_CONFIG_BACKUP
            for config in ${USER_CONFIG_LIST[@]}
            do
                mv $USER_CONFIG_DIR/$config $USER_CONFIG_BACKUP/
                cp -fr $NEW_CONFIG_DIR/$config $USER_CONFIG_DIR/$config
                echo "$USER_CONFIG_DIR/$config copied ..."
            done
            echo "Copying configuration done ..."
            echo "Old local configuration files have been moved to $USER_CONFIG_BACKUP"
            break
            ;;
        'pass')
            echo "Copying/Linking configuration passed ..."
            break
            ;;
    esac
done

# ----------------------------------------------------------------------------
# Section 3 - Script to install needed packages
# ----------------------------------------------------------------------------
# Packages needed for my i3 work environment

# Terminal package
install_terminal_package () {
    echo
    echo "Terminal package including:"
    echo "-- Terminal: kitty, gnome-terminal"
    echo "-- Shell: fish"
    echo "-- TUI tool: fish, git"
    echo "Installation requires sudo permission"
    # Terminal emulator, shell tools and etc.
    sudo dnf install kitty gnome-terminal fish tmux git
}

# Input method package
install_input_method_package () {
    echo
    echo "Input method package including:"
    echo "-- Input method: ibus, ibus-chewing"
    echo "Installation requires sudo permission"
    # Ibus input
    sudo dnf install ibus ibus-chewing
}

# X-compositor
install_xcompositor_package () {
    echo
    echo "Xcompositor package including:"
    echo "-- Xcompositor: picom"
    echo "Installation requires sudo permission"
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
}

# X-window tools
install_xwindow_tool_package () {
    echo
    echo "X-window tool package including:"
    echo "-- Display manager: xrandr, arandr, xbacklight, redshift, i3lock, xss-lock"
    echo "-- Mouse cursor: imwheel, libinput, unclutter-xfixes"
    echo "-- Keyboard: xdotool, xset, numlockx, screenkey"
    echo "-- System monitor: conky"
    echo "Installation requires sudo permission"
    # X-window tools
    sudo dnf install xrandr arandr xbacklight redshift i3lock xss-lock \
                     imwheel libinput unclutter-xfixes \
                     xdotool xset numlock screenkey \
                     conky
}

# Audio tools
install_audio_tool_package () {
    echo
    echo "Audio tool package including:"
    echo "-- Audio manager: pavucontrol, pulseaudio, pulsemixer, playerctl"
    echo "-- Audio visualizer: cava"
    echo "Installation requires sudo permission"
    # Audio controls
    sudo dnf install pavucontrol pulseaudio playerctl
    python -m pip install pulsemixer
    # Cava/Vis [https://github.com/dpayne/cli-visualizer]
    sudo dnf install cava
    sudo dnf install fftw-devel ncurses-devel pulseaudio-libs-devel cmake
    cd $HOME/Desktop
    git clone https://github.com/dpayne/cli-visualizer.git
    cd cli-visualizer
    sudo ./install.sh
}

# i3 gap
install_i3_gap_packages () {
    echo
    echo "i3 gap package including:"
    echo "-- i3 gap: fuhrmann/i3-gaps"
    echo "-- i3 bar: bumblebee-status"
    echo "-- i3 tool: dunst, rofi, autotiling, flashfocus, i3-workspace-swap, i3-resurrect"
    echo "Installation requires sudo permission"
    # i3 gap
    sudo dnf copr enable fuhrmann/i3-gaps
    sudo dnf install i3-gaps
    # i3 tools
    python -m pip install autotiling flashfocus i3-workspace-swap i3-resurrect
    sudo dnf install dunst rofi
    # Bumblebee-status [https://github.com/tobi-wan-kenobi/bumblebee-status]
    cd $HOME/Desktop
    python -m pip install bumblebee-status i3ipc utils
    sudo dnf install python-netifaces lm_sensors pulseaudio-utils python3-psutil
}

# Theme
install_theme_packages () {
    echo
    echo "Theme package including:"
    echo "-- Theme: arc-theme papirus-icon-theme"
    echo "-- GTK: gtk-chtheme lxappearance"
    echo "-- QT: qt-config qt5ct qt5-qtstyleplugins kvantum"
    echo "-- Wallpaper tool: feh variety pywal"
    echo "-- Font: Droid Sans Mono for Powerline Nerd Font"
    echo "Installation requires sudo permission"
    # Theme configurator and fonts
    sudo dnf install gtk-chtheme lxappearance
    sudo dnf install qt-config qt5ct qt5-qtstyleplugins kvantum
    sudo dnf install arc-theme papirus-icon-theme
    sudo dnf install feh variety pywal
    cd $HOME/Desktop
    mkdir -p $HOME/.local/share/fonts
    cd $HOME/.local/share/fonts
    curl -fLo "Droid Sans Mono for Powerline Nerd Font Complete.otf" "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete.otf"
}

# Editor tools
install_editor_tool_packages () {
    echo
    echo "Editor tool package including:"
    echo "-- Text editor: neovim"
    echo "-- Clipboard manager: parcellite"
    echo "-- Markdown viewer: glow"
    echo "-- PDF viewer: zathura, okular"
    echo "Installation requires sudo permission"
    # Text editor tools
    sudo dnf install neovim parcellite
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
}

# Python tools
install_python_tool_packages () {
    echo
    echo "Python tool package including:"
    echo "-- pynvim: neovim python plugin"
    echo "-- ipdb: python debugger"
    echo "-- jedi: python autocompletion"
    python -m pip install pynvim ipdb jedi
}

# Misc tools
install_misc_tool_packages () {
    echo
    echo "Miscellaeous tool package including:"
    echo "-- Gnome software: polkit-gnome, gnome-screenshot, nautilus"
    echo "-- File manager: ranger"
    echo "-- Bluetooth: blueman"
    echo "-- Network: NetworkManager, brave-browser, firefox"
    echo "-- Miscellaeous: flameshot"
    echo "Installation requires sudo permission"
    # Gnome softwares
    sudo dnf install polkit-gnome gnome-screenshot nautilus
    # Bluetooth
    sudo dnf install blueman
    # Network
    sudo dnf install NetworkManager brave-browser firefox
    # Ranger [https://github.com/ranger/ranger]
    cd $HOME/Desktop
    sudo dnf install ranger w3m w3m-img
    git clone https://github.com/alexanderjeurissen/ranger_devicons.git ~/.config/ranger/plugins/ranger_devicons
    # Miscellaeous
    sudo dnf install flameshot
}


PACKAGE_LIST=( install_terminal_package \
               install_python_tool_packages \
               install_input_method_package \
               install_xcompositor_package \
               install_xwindow_tool_package \
               install_audio_tool_package \
               install_i3_gap_packages \
               install_theme_packages \
               install_editor_packages \
               install_misc_tool_packages \
             )

section3_greetings () {
    echo
    echo '# ============== Section 3 - Package Installation ================ #'
    echo '# This section is to install needed package for working enviroment #'
    echo '# ================================================================ #'
    echo '# Package list:'
    for package in ${PACKAGE_LIST[@]};
    do
        echo "# -- $package"
    done
    echo
}

section3_greetings
echo "Do you want to install needed package/tool for working enviroment ?"
select option in \
    'yes' \
    'no'
do
    case $option in
        'yes')
            for package in ${PACKAGE_LIST[@]};
            do
                $package
            done
            echo "Package installation is done ..."
            break
            ;;
        'no')
            echo "Package installation is ignored ..."
            break
            ;;
    esac
done
