# I3WM Customization Note

Table of Contents
=================

* [I3WM Customization Note](#i3wm-customization-note)
* [Context](#context)
   * [Environments Setup](#environments-setup)
      * [Install i3-gaps in Fedora 33](#install-i3-gaps-in-fedora-33)
      * [Add I3 working environment](#add-i3-working-environment)
      * [Swap workspace](#swap-workspace)
      * [Save workspace layout](#save-workspace-layout)
      * [Automatic rename workspace with icons [conflict with save workspace]](#automatic-rename-workspace-with-icons-conflict-with-save-workspace)
   * [GUI Theme Configuration](#gui-theme-configuration)
      * [Theme configuration](#theme-configuration)
      * [Check whether program using GTK or QT](#check-whether-program-using-gtk-or-qt)
      * [Example: program and it corresponding tookit](#example-program-and-it-corresponding-tookit)
      * [My current color theme setup for arc-dark-theme](#my-current-color-theme-setup-for-arc-dark-theme)
   * [Keyboard and Trackpad Setup](#keyboard-and-trackpad-setup)
      * [Trackpad](#trackpad)
      * [Keyboard](#keyboard)
      * [Reference](#reference)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# Context

## Environments Setup
This modified configuration file is highly refered to link below
- https://i3wm.org/docs/userguide.html
- https://github.com/levinit/i3wm-config
- https://www.itread01.com/p/142448.html
- https://medium.com/@mudrii/archlinux-tutorial-part-3-i3-configuration-and-operation-9cd6dc90e524
- https://github.com/alberto-santini/i3-configuration-x1
- https://segmentfault.com/a/1190000022083424
- https://github.com/Airblader/i3 (i3-gap)

### Install i3-gaps in Fedora 33
- Installation:
    ```
    sudo dnf copr enable fuhrmann/i3-gaps
    sudo dnf install i3-gaps
    ```

### Add I3 working environment
- Below commands must be added to shell dotfile (e.g. .bashrc .zshrc and etc.)
    ```
    # export I3_SCRIPT="$HOME/.config/i3/script"
    # export PATH="$I3_SCRIPT:$PATH"
    ```

### Swap workspace
- i3-workspace-swap (https://pypi.org/project/i3-workspace-swap/)
- Installation: `pip install i3-workspace-swap`

### Save workspace layout
- i3-resurrect (https://pypi.org/project/i3-resurrect/)
- Installation: `pip install i3-resurrect`

### Automatic rename workspace with icons [conflict with i3-resurrect]
- i3-workspace-names-daemon (https://github.com/cboddy/i3-workspace-names-daemon)
- Awesome font and icons (https://origin.fontawesome.com/icons?d=gallery)

## GUI Theme Configuration
This session modifies software GUI theme configuration

### Theme configuration
Detailed theme and font Setup
- https://askubuntu.com/questions/598943/how-to-de-uglify-i3-wm
- https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications
    - for gtk:
        - for gtk2.x: `sudo dnf install gtk-chtheme`
        - for gtk3.x: `sudo dnf install lxappearance`
    - for qt/kde:
        - for qt4: `sudo dnf install qt-config`
        - for qt5: `sudo dnf install qt5ct qt5-qtstyleplugins`
        - for qt/kde: `sudo dnf install kvantum`

### Check whether program using GTK or QT
- https://askubuntu.com/questions/840256/detect-if-an-application-uses-gtk-or-qt
-  In command line,
    - `ldd $(which PROGRAM) | grep 'gtk'` -> using GTK
    - `ldd $(which PROGRAM) | grep 'qt'`  -> using QT

### Example: program and it corresponding tookit
- gtk
    - brave-browser, nautilus, parcellite, and etc.
- qt/kde
    - mendeleydestop, okular, kde connect and etc.

### My current color theme setup for arc-dark-theme
- Theme
    - lxappearance: Arc-Dark-solid
    - gtk-chtheme: Arc-Dark-solid
    - kvantum: KvArcDark
        - qt5 Settings: kvantum-dark
        - qt4 Config: Desktop Settings (Default)
- Icon
    - Light: Papirus
    - Dark: Papirus-Dark
- Font
    - SAN regular 11
    - SAN serif regular 11
- Flatpak applications
    - https://itsfoss.com/flatpak-app-apply-theme/

## Keyboard and Trackpad Setup
This session modifies keyboard keymap and operation for laptop trackpad

### Trackpad
```
# Setup trackpad natural scrolling in i3 && Setup trackpad tap in i3
# In /usr/share/X11/xorg.conf.d/40-libinput.conf, add the following
#
# Section "InputClass"
#       Identifier "libinput touchpad catchall"
#       MatchIsTouchpad "on"
#       MatchDevicePath "/dev/input/event*"
#       Driver "libinput"
#       Option "NaturalScrolling" "True"
#       Option "Tapping" "On"
# EndSection
```

### Keyboard
```
# Remap Capslock to Win/Ctrl
#
# Option 1 - Need root permission. In /etc/X11/xorg.conf.d/00-keyboard.conf, add the following
#
# Section "InputClass"
#       Identifier "system-keyboard"
#       MatchIsKeyboard "on"
#       Option "XkbLayout" "us"
#       # Uncomment below line for setting [caplock -> super]
#       #Option "XkbOptions" "caps:super"
#       # Uncomment below line for setting [caplock -> ctrl]
#       #Option "XkbOptions" "ctrl:nocaps"
# EndSection
#
# Option 2 - If you don't have root permission. In i3 config, add the following
#
# # [caplock -> ctrl]
# exec_always --no-startup-id setxkbmap -option "ctrl:nocaps"
# # Reset caplock key [ctrl -> caplock], in terminal,
# setxkbmap -option "ctrl:aa_ctrl"

# Key bindsym name search
# Use xev to find out bindsym name of key interactively
# Use xmodmap -pke to print out all keycode
```

### Reference
- https://askubuntu.com/questions/1122513/how-to-add-natural-inverted-mouse-scrolling-in-i3-window-manager
- https://cravencode.com/post/essentials/enable-tap-to-click-in-i3wm/
- https://www.reddit.com/r/i3wm/comments/cqefj3/mapping_symbols/
