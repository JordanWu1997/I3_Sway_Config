#!/usr/bin/env bash
# ============================================================================
# This shell script is to install my i3 configuration and work environment
# ============================================================================

# ----------------------------------------------------------------------------
# Section 1 - Environment variables
# ----------------------------------------------------------------------------

load_shell_configuration () {
    case $SHELL in
        '/bin/bash' | '/usr/bin/bash')
            SHELL_CONFIG="$HOME/.bashrc"
            PROFILE="$HOME/.profile"
            ;;
        '/bin/zsh' | '/usr/bin/zsh')
            SHELL_CONFIG="$HOME/.zshrc"
            PROFILE="$HOME/.profile"
            ;;
        '/bin/fish' | '/usr/bin/fish')
            SHELL_CONFIG="$HOME/.config/fish/config.fish"
            PROFILE="$HOME/.profile"
            ;;
        *)
            SHELL_CONFIG="$HOME/.bashrc"
            PROFILE="$HOME/.profile"
    esac
}
load_shell_configuration

desc_profile_and_enviroment_variables () {
    echo "Following lines will be added to ${PROFILE} and"
    echo "the funtion that loads ${PROFILE} will be added"
    echo "to ${SHELL_CONFIG} for ${SHELL}"
    echo ''
    echo '# ============================================'
    cat "./config/i3/share/default_profile"
    echo '# ============================================'
    echo ''
}

# Add .profile to shell configuration based on $SHELL
add_profile_to_shell_configuration () {
    case $1 in
        "$HOME/.zshrc")
            echo ''                                               >> "$1"
            echo '# ============================================' >> "$1"
            echo '# Followings are added by i3 script install.sh' >> "$1"
            echo "# At $(date)"                                   >> "$1"
            echo '# ============================================' >> "$1"
            echo '# Run ~/.profile'                               >> "$1"
            echo 'emulate sh -c ". ~/.profile"'                   >> "$1"
            ;;
        *)
            echo ''                                               >> "$1"
            echo '# ============================================' >> "$1"
            echo '# Followings are added by i3 script install.sh' >> "$1"
            echo "# At $(date)"                                   >> "$1"
            echo '# ============================================' >> "$1"
            echo '# Run ~/.profile'                               >> "$1"
            echo 'source ~/.profile'                              >> "$1"
    esac
}

# Add following lines to configuration file
add_enviroment_variables_to_profile () {
    echo ''                                               >> "$1"
    echo '# ============================================' >> "$1"
    echo '# Followings are added by i3 script install.sh' >> "$1"
    echo "# At $(date)"                                   >> "$1"
    echo '# ============================================' >> "$1"
    cat "./config/i3/share/default_profile"               >> "$1"
    echo '# ============================================' >> "$1"
}


section1_greetings () {
    echo
    echo '# ============= Section 1 - Environment Variable =============== #'
    echo '# This section is to add environment variables to $HOME/.profile #'
    echo '# ============================================================== #'
    echo
}

section1_greetings
desc_profile_and_enviroment_variables
echo "Do you want to add environment variables and profile-loading function?"
select option_section1 in \
    'no' \
    'yes'
do
    case ${option_section1} in
        'yes')
            add_profile_to_shell_configuration "$SHELL_CONFIG"
            add_enviroment_variables_to_profile "$PROFILE"
            echo "Environment variables are added to $PROFILE ..."
            echo "Profile-loading function is added to $ $SHELL_CONFIG"
            break
            ;;
        'no')
            echo "Adding environment variables is ignored ..."
            echo "Adding profile-loading function is ignored ..."
            break
            ;;
    esac
done

# ----------------------------------------------------------------------------
# Section 2 - Link/Copy configuration files/directories to $HOME/.config/*
# ----------------------------------------------------------------------------
# Link/copy config directories/files under ~/.config
NEW_CONFIG_DIR="$HOME/Desktop/I3_Sway_Config/config"
USER_CONFIG_DIR="$HOME/.config"
USER_CONFIG_BACKUP="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
USER_CONFIG_LIST=( \
    bumblebee-status cava conky dunst feh flashfocus glow htop \
    i3 kitty Kvantum ncspot neofetch parcellite picom ranger rofi \
    spotify-tui vis zathura \
    libinput-gestures.conf starship.toml \
)

section2_greetings () {
    echo
    echo '# ========== Section 2 - Configuration ========== #'
    echo '# This section is to copy/link configuration file #'
    echo '# =============================================== #'
    echo
}

section2_greetings
echo "What do you want to do with new configuration files (${USER_CONFIG_DIR})?"
select option in \
    'ignore' \
    'link' \
    'copy'
do
    case ${option} in
        'link')
            mkdir "${USER_CONFIG_BACKUP}"
            for config in "${USER_CONFIG_LIST[@]}"; do
                mv "${USER_CONFIG_DIR}/${config}" "${USER_CONFIG_BACKUP}/"
                command ln -s "${NEW_CONFIG_DIR}/${config}" "${USER_CONFIG_DIR}"
                echo "${USER_CONFIG_DIR}/${config} linked ..."
            done
            echo "Linking configuration done ..."
            echo "Old local configuration files have been moved to ${USER_CONFIG_BACKUP}"
            break
            ;;
        'copy')
            mkdir "${USER_CONFIG_BACKUP}"
            for config in "${USER_CONFIG_LIST[@]}"; do
                mv "${USER_CONFIG_DIR}/${config}" "${USER_CONFIG_BACKUP}/"
                cp -fr "${NEW_CONFIG_DIR}/${config}" "${USER_CONFIG_DIR}/${config}"
                echo "${USER_CONFIG_DIR}/${config} copied ..."
            done
            echo "Copying configuration done ..."
            echo "Old local configuration files have been moved to ${USER_CONFIG_BACKUP}"
            break
            ;;
        'ignore')
            echo "Copying/Linking configuration is ignored (passed) ..."
            break
            ;;
    esac
done

# ----------------------------------------------------------------------------
# Section 3 - Script to install needed packages
# ----------------------------------------------------------------------------
# Packages needed for my i3 work environment

# Add RPM repositories
desc_RPM_repositories () {
    echo
    echo "RPM repositories including:"
    echo "-- rpmfusion: both free and non-free repositories"
    echo "-- rpmshere: rpmsphere repository"
    echo "Installation requires sudo permission"
}
add_RPM_repositories () {
    # Add free/non-free rpmfusion repository
    sudo dnf install -y \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
    # TODO: Add rpmsphere repository
    #sudo dnf install -y rpmsphere-release
}

# Terminal packages
desc_terminal_packages () {
    echo
    echo "Terminal packages including:"
    echo "-- Terminal: kitty, gnome-terminal"
    echo "-- Shell: fish"
    echo "-- TUI tool: tmux, git, htop"
    echo "-- Complier: golang"
    echo "-- Package Manager (Python): pip"
    echo "-- Package Manager (Rust): cargo"
    echo "-- JSON processor: jq"
    echo "Installation requires sudo permission"
}
install_terminal_packages () {
    # Terminal emulator
    sudo dnf install -y kitty gnome-terminal
    # Shell
    sudo dnf install -y fish
    # TUI tool
    sudo dnf install -y tmux git htop
    # Complier: golang
    sudo dnf install -y golang
    # Package Manager (Rust): cargo
    sudo dnf install -y cargo
    # JSON processor
    sudo dnf install -y jq
    # Install pip with dnf if there is no one
    command -v pip || sudo dnf install -y python3-pip
}

# Add environment variable for ibus
add_environment_variables_for_ibus () {
    echo ''                                               >> "$1"
    echo '# =================== iBUS ===================' >> "$1"
    echo 'export GTK_IM_MODULE=ibus'                      >> "$1"
    echo 'export XMODIFIER="@im=ibus"'                    >> "$1"
    echo 'export DefaultIMModule=ibus'                    >> "$1"
    echo 'export QT_IM_MODULE=ibus'                       >> "$1"
    echo 'export GLFW_IM_MODULE=ibus'                     >> "$1"
    echo '# ============================================' >> "$1"
}

# Input method packages
desc_input_method_packages () {
    echo
    echo "Input method packages including:"
    echo "-- Input method: ibus, ibus-chewing"
    echo "Installation requires sudo permission"
}
install_input_method_packages () {
    # Ibus input
    sudo dnf install -y ibus ibus-chewing
    # Add environment variable for ibus
    add_environment_variables_for_ibus "${PROFILE}"
    echo "ibus environment variables are added to ${PROFILE} ..."
}

# X-compositor
desc_xcompositor_packages () {
    echo
    echo "Xcompositor packages including:"
    echo "-- Xcompositor: picom"
    echo "Installation requires sudo permission"
}
install_xcompositor_packages () {
    # TODO: jonaburg-fork is not complied successfully
    ## Picom [https://github.com/jonaburg/picom]
    #sudo dnf install -y meson gcc ninja-build cmake libev-devel xcb-util-devel \
                     #libX11-devel xcb-util-renderutil-devel xcb-util-image \
                     #xcb-util-image-devel xcb-util-renderutil-devel pixman-devel \
                     #uthash-devel libconfig-devel pcre-devel mesa-libGL-devel \
                     #dbus-devel libXext-devel
    #cd $HOME/Desktop
    #git clone https://github.com/jonaburg/picom.git
    #cd picom
    #git submodule update --init --recursive
    #meson --buildtype=release . build
    #sudo ninja -C build

    # For now, use fedora-fork
    sudo dnf install -y picom
}

# X-window tools
desc_xwindow_tool_packages () {
    echo
    echo "X-window tool packages including:"
    echo "-- Display manager: xrandr, arandr"
    echo "-- Window controller: wmctrl"
    echo "-- Screen: xbacklight, redshift, i3lock, xss-lock, xcolor"
    echo "-- Mouse: imwheel, libinput, unclutter-xfixes, warpd"
    echo "-- Keyboard: xdotool, xset, numlockx, screenkey"
    echo "-- System monitor: conky"
    echo "-- Touchpad: libinput-gestures"
    echo "Installation requires sudo permission"
}
install_xwindow_tool_packages () {
    # Display manager: xrandr, arandr
    sudo dnf install -y xrandr arandr
    # Window controller: wmctrl
    sudo dnf install -y wmctrl
    # Screen: xbacklight, redshift, i3lock, xss-lock
    sudo dnf install -y xbacklight redshift i3lock xss-lock
    # Screen: xcolor
    cargo install xcolor
    # Mouse: imwheel, libinput, unclutter-xfixes
    sudo dnf install -y imwheel libinput unclutter-xfixes
    # Keyboard: xdotool, xset, numlockx, screenkey
    sudo dnf install -y xdotool xset numlockx screenkey
    # System monitor: conky
    sudo dnf install -y conky
    # Touchpad: libinput-gestures
    sudo dnf install wmctrl xdotool
    cd "$HOME/Desktop"
    git clone https://github.com/bulletmark/libinput-gestures.git
    cd libinput-gestures
    sudo ./libinput-gestures-setup install
    # libinput-gestures requires user to be in the group input
    sudo gpasswd -a "$USER" input
    # Mouse emulator: warpd
    cd "$HOME/Desktop"
    git clone https://github.com/rvaiya/warpd.git
    cd warpd
    make && sudo make install
}

# Audio tools
desc_audio_tool_packages () {
    echo
    echo "Audio tool packages including:"
    echo "-- Player controller: mpv-mpris"
    echo "-- Audio manager: pavucontrol, pulseaudio, pulsemixer, playerctl"
    echo "-- Audio visualizer: cava"
    echo "Installation requires sudo permission"
}
install_audio_tool_packages () {
    # Player controller: mpv-mpris
    sudo dnf install -y mpv-mpris
    # Audio managers
    sudo dnf install -y pavucontrol pulseaudio playerctl
    /usr/bin/python -m pip install pulsemixer --user
    # Audio visualizer: cava
    sudo dnf install -y cava
    # TODO: vis is not complied successfully
    ## Vis [https://github.com/dpayne/cli-visualizer]
    #sudo dnf install -y fftw-devel ncurses-devel pulseaudio-libs-devel cmake
    #cd $HOME/Desktop
    #git clone https://github.com/dpayne/cli-visualizer.git
    #cd cli-visualizer
    #sudo ./install.sh
}

# i3/i3-gap (i3-gap has been merged to i3 in i3 v4.22)
desc_i3_packages () {
    echo
    echo "i3 packages including:"
    #echo "-- i3 gap: fuhrmann/i3-gaps"
    echo "-- i3 window manager: i3"
    echo "-- i3 bar: bumblebee-status"
    echo "-- i3 tool: dunst, rofi, autotiling, flashfocus, i3-workspace-swap, i3-resurrect"
    echo "Installation requires sudo permission"
}
install_i3_packages () {
    ## i3-gap (i3-gap has been merged to i3 in i3 v4.22)
    #sudo dnf copr enable fuhrmann/i3-gaps
    #sudo dnf install -y i3-gaps
    sudo dnf install -y i3
    # i3 tools
    /usr/bin/python -m pip install autotiling flashfocus i3-workspace-swap i3-resurrect --user
    sudo dnf install -y dunst rofi
    # Bumblebee-status [https://github.com/tobi-wan-kenobi/bumblebee-status]
    /usr/bin/python -m pip install bumblebee-status==2.0.5 i3ipc utils --user
    sudo dnf install -y python-netifaces lm_sensors pulseaudio-utils python3-psutil
}

# Customization
desc_customization_packages () {
    echo
    echo "Customization packages including:"
    echo "-- Theme: arc-theme papirus-icon-theme"
    echo "-- GTK: gtk-chtheme lxappearance"
    echo "-- QT: qt-config qt5ct qt5-qtstyleplugins kvantum"
    echo "-- Wallpaper tool: feh variety pywal"
    echo "-- Font: Droid Sans Mono for Powerline Nerd Font"
    echo "-- Auto-theme: pywal"
    echo "Installation requires sudo permission"
}
install_customization_packages () {
    # Theme configurer and fonts
    sudo dnf install -y gtk-chtheme lxappearance
    sudo dnf install -y qt-config qt5ct qt5-qtstyleplugins kvantum
    sudo dnf install -y feh variety
    sudo dnf install -y arc-theme papirus-icon-theme
    # Font
    cd "$HOME/Desktop"
    mkdir -p "$HOME/.local/share/fonts"
    cd "$HOME/.local/share/fonts"
    curl -fLo \
        "Droid Sans Mono for Powerline Nerd Font Complete.otf" \
        "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete.otf"
    # Theme: pywal
    cd "$HOME/Desktop"
    git clone https://github.com/sonjiku/pywal.git
    cd pywal
    /usr/bin/python -m pip install . --user
}

# Editor tools
desc_editor_tool_packages () {
    echo
    echo "Editor tool packages including:"
    echo "-- Text editor: vim neovim"
    echo "-- Clipboard manager: parcellite"
    #echo "-- Markdown viewer: glow"
    echo "-- PDF viewer: zathura, okular"
    echo "Installation requires sudo permission"
}
install_editor_tool_packages () {
    # Text editor tools
    sudo dnf install -y vim neovim
    # Clipboard manager: parcellite
    sudo dnf install -y parcellite
    ## Glow [https://github.com/charmbracelet/glow]
    #cd $HOME/Desktop
    #git clone https://github.com/charmbracelet/glow.git
    #cd glow
    #sudo go build
    # Okular
    sudo dnf install okular
    # Zathura and pdf-plugins
    sudo dnf install -y zathura 'zathura-*'
    # Zathura-pywal [https://github.com/mlscarlson/zathura-pywal]
    cd "$HOME/Desktop"
    git clone https://github.com/mlscarlson/zathura-pywal.git
    cd zathura-pywal
    sudo make install
}

# Python tools
desc_python_tool_packages () {
    echo
    echo "Python tool packages including:"
    echo "-- pynvim: neovim python plugin"
    echo "-- ipdb: python debugger"
    echo "-- jedi: python autocompletion"
}
install_python_tool_packages () {
    /usr/bin/python -m pip install pynvim ipdb jedi --user
}

# Misc tools
desc_misc_tool_packages () {
    echo
    echo "Miscellaneous tool packages including:"
    echo "-- Gnome software: polkit-gnome, gnome-screenshot, nautilus"
    echo "-- File manager: ranger"
    echo "   -- File previewer: exiftool, mediainfo"
    echo "   -- Compressed file previewer: atool, untar, p7zip-plugins"
    echo "   -- HTML previewer: w3m, w3m-img"
    echo "   -- Image previewer: imagemagick, ueberzug, librsvg2-tools"
    echo "   -- Video previewer: ffmpegthumbnailer"
    echo "   -- PDF previewer: pdftotext pdftoppm"
    echo "   -- EPUB previewer: calibre"
    echo "   -- Text previewer: catdoc, pandoc"
    echo "   -- Font previewer: fontforge"
    echo "-- Bluetooth: blueman"
    echo "-- Network: NetworkManager, brave-browser, firefox"
    echo "-- Screenshot: flameshot, peek"
    echo "-- OCR Tool: tesseract, tesseract-langpak-eng, tesseract-langpack-chi_tra"
    echo "-- Magnifier: magnus"
    echo "Installation requires sudo permission"
}
install_misc_tool_packages () {
    # Gnome software
    sudo dnf install -y polkit-gnome gnome-screenshot nautilus
    # Bluetooth
    sudo dnf install -y blueman
    # Network
    sudo dnf install -y NetworkManager brave-browser firefox
    # Ranger [https://github.com/ranger/ranger]
    sudo dnf install -y ranger
    # File previewer
    sudo dnf install -y exiftool mediainfo
    # Compressed file previewer
    sudo dnf install -y atool unrar p7zip-plugins
    # HTML previewer, image preview engine
    sudo dnf install -y w3m w3m-img
    # Image previewer
    sudo dnf install -y imagemagick librsvg2-tools
    # Video previewer
    sudo dnf install -y ffmpegthumbnailer
    # PDF previewer
    sudo dnf install -y pdftotext pdftoppm
    # EPUB previewer
    sudo dnf install -y calibre
    # Text, Word, Excel previewer
    sudo dnf install -y catdoc pandoc
    # Font previewer
    sudo dnf install -y fontforge
    # Ueberzug
    sudo dnf install -y libXres-devel
    cd "$HOME/Desktop"
    git clone https://github.com/ueber-devel/ueberzug.git
    cd ueberzug
    /usr/bin/python setup.py install --user
    # Modeline Devicons
    cd "$HOME/Desktop"
    git clone \
        https://github.com/alexanderjeurissen/ranger_devicons.git \
        "$HOME/.config/ranger/plugins/ranger_devicons"
    git clone \
        https://github.com/cdump/ranger-devicons2 \
        "$HOME/.config/ranger/plugins/devicons2"
    # Screenshot and recording
    sudo dnf install -y flameshot peek
    # OCR Tool
    sudo dnf install -y tesseract tesseract-langpak-eng tesseract-langpack-chi_tra
    # Magnifier
    sudo dnf install python3-setproctitle
    cd "$HOME/Desktop"
    git clone https://github.com/stuartlangridge/magnus.git
    cd magnus
    sudo python setup.py install
}

PACKAGE_LIST=( terminal_packages \
               editor_tool_packages \
               input_method_packages \
               i3_packages \
               xcompositor_packages \
               xwindow_tool_packages \
               audio_tool_packages \
               customization_packages \
               python_tool_packages \
               misc_tool_packages \
             )

section3_greetings () {
    echo
    echo '# =============== Section 3 - Package Installation ================= #'
    echo '# This section is to install needed packages for working environment #'
    echo '# ================================================================== #'
    echo '# Package list:'
    for package in "${PACKAGE_LIST[@]}"; do
        echo "# -- ${package}"
    done
    echo
}

section3_greetings
echo "Do you want to install needed package for working environment ?"
select option_section3 in \
    'no' \
    'yes (one-by-one)' \
    'yes (all)'
do
    case ${option_section3} in
        'no')
            echo "Package installation is ignored ..."
            break
            ;;
        'yes (one-by-one)')
            # Add RPM repositories
            echo
            echo "Do you want to enable other RPM repositories ?"
            desc_RPM_repositories
            echo
            select option in \
                'no' \
                'yes'
            do
                case ${option} in \
                    'no')
                        echo "No RPM repository is enabled ..."
                        echo
                        break
                        ;;
                    'yes')
                        add_RPM_repositories
                        echo
                        break
                        ;;
                esac
            done
            # Install packages one-by-one
            for package in "${PACKAGE_LIST[@]}"; do
                echo "Do you want to install ${package} ?"
                "desc_${package}"
                echo
                select option in \
                    'no' \
                    'yes'
                do
                    case ${option} in
                        'no')
                            echo "${package} is ignored ..."
                            echo
                            break
                            ;;
                        'yes')
                            "install_${package}"
                            echo "${package} installation is done ..."
                            echo
                            break
                            ;;
                    esac
                done
            done
            break
            ;;
        'yes (all)')
            # Add RPM repositories
            echo
            echo "Do you want to enable other RPM repositories ?"
            echo
            desc_RPM_repositories
            select option in \
                'no' \
                'yes'
            do
                case ${option} in \
                    'no')
                        echo "No RPM repository is enabled ..."
                        echo
                        break
                        ;;
                    'yes')
                        add_RPM_repositories
                        echo
                        break
                        ;;
                esac
            done
            # Install all packages
            for package in "${PACKAGE_LIST[@]}"; do
                echo "${package}"
                "desc_${package}"
                echo
                "install_${package}"
            done
            echo "Package installation is done ..."
            break
            ;;
    esac
done

# ----------------------------------------------------------------------------
# Section 4 - End of my i3 environment installation
# ----------------------------------------------------------------------------
# End of environment installation. Note there are still some TODO things

section4_greetings () {
    echo
    echo '# ============== Section 4 - End of Installation ==================== #'
    echo '# This is the end of my i3 environment installation. Hope you like it #'
    echo '# =================================================================== #'
    echo
}

section4_greetings
# Set default picom
if [ ! -f "$HOME/.config/picom/picom.conf" ]; then
    i3_default_valuechanger.sh picom transparency
fi
# Set default flashfocus
if [ ! -f "$HOME/.config/flashfocus/flashfocus.yml" ]; then
    i3_default_valuechanger.sh flashfocus opaque
fi
# Set default conky
if [ ! -f "$HOME/.config/conky/conky_config_bindkey" ] \
    && [ -f "$HOME/.config/conky/conky_config_system" ]; then
    i3_default_valuechanger.sh conky_style minimal
fi

# Post-installation
echo "Post-installation TODO things"
echo "(1) set default theme that is not pywal but templates"
echo "(2) set GTK/QT color theme with lxappearance/(Kvantum, qt5, qt4)"
echo "(3) set chewing as primary input method"
echo "(4) flatpak packages installation and customization"
echo "(5) dotfiles (e.g. .Xresources)"
