# I3WM Customization Note

# Table of Contents

- [I3WM Customization Note](#i3wm-customization-note)
- [Context](#context)
  - [Environments Setup](#environments-setup)
    - [Install i3-gaps in Fedora 33](#install-i3-gaps-in-fedora-33)
    - [Add I3 working environment](#add-i3-working-environment)
    - [Swap workspace](#swap-workspace)
    - [Save workspace layout](#save-workspace-layout)
    - [Automatic rename workspace with icons [conflict with save workspace]](#automatic-rename-workspace-with-icons-conflict-with-save-workspace)
  - [GUI Theme Configuration](#gui-theme-configuration)
    - [Theme configuration](#theme-configuration)
    - [Check whether program using GTK or QT](#check-whether-program-using-gtk-or-qt)
    - [Example: program and it corresponding tookit](#example-program-and-it-corresponding-tookit)
    - [My current color theme setup for arc-dark-theme](#my-current-color-theme-setup-for-arc-dark-theme)
  - [Keyboard and Trackpad Setup](#keyboard-and-trackpad-setup)
    - [Trackpad](#trackpad)
    - [Keyboard](#keyboard)
    - [Reference](#reference)
  - [Screen Lock and Idle Dimming](#screen-lock-and-idle-dimming)
    - [How it works](#how-it-works)
    - [Setup](#setup)
    - [Test the dimming with xset](#test-the-dimming-with-xset)
    - [Test the idle inhibitor](#test-the-idle-inhibitor)
    - [Restore the normal timing](#restore-the-normal-timing)
    - [Tuning](#tuning)
    - [Troubleshooting](#troubleshooting)

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

  ```bash
  sudo dnf copr enable fuhrmann/i3-gaps
  sudo dnf install i3-gaps
  ```

### Add I3 working environment

- Below commands must be added to shell dotfile (e.g. .bashrc .zshrc and etc.)

  ```bash
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
- In command line,
  - `ldd $(which PROGRAM) | grep 'gtk'` -> using GTK
  - `ldd $(which PROGRAM) | grep 'qt'` -> using QT

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
#       Option "TappingButtonMap" "lrm"
#       Option "ScrollMethod" "twofinger"
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
- https://cravencode.com/post/essentials/enable-tap-to-click-in-i3wm/
- https://blog.ruo-chen.wang/2020/01/switch-from-gnome-to-i3.html
- https://wiki.archlinux.org/title/libinput

## Screen Lock and Idle Dimming

### How it works

When the session is idle, the screens fade down for 10 seconds before the lock, and
any key or mouse movement in that time cancels the lock.

| Idle time | What happens | Done by |
| :-- | :-- | :-- |
| 9:50 | "Locking in 10 s" notification, every monitor fades to 30% over 8 s | X screen saver activates, `xss-lock --notifier` runs `i3_idle_dim.sh` |
| 10:00 | Brightness restored, `i3lock` starts | X screen saver cycle, `xss-lock` runs `i3_i3lock_operator.sh` |
| 10:10 | Screens turn off | DPMS |

- The timing is set by `xset s 590 10 dpms 610 610 610` in
  `script/i3_toolkit_operator.sh disable_caffeine`, which `i3_startup.config` runs at login.
  `590` is when the dim starts; `10` (the screen saver cycle) is the warning before the lock.
- `script/i3_idle_inhibitor.sh` skips all of this while a fullscreen window is visible or
  the microphone is in use (videos, calls). Music alone does not count.
- Locking by hand (`loginctl lock-session`, System mode then `l`) and locking on suspend
  skip the warning.
- Caffeine (Toolkit mode, then `Shift+c`) turns the screen saver and DPMS off, so nothing
  dims, locks or turns off.

### Setup

Everything starts at login. To apply changes without logging out:

```bash
# Restart xss-lock with the dim notifier (also done by Mod+Shift+r)
~/.config/i3/script/i3_xsslock_operator.sh current_desktop
# Apply the normal timing
~/.config/i3/script/i3_toolkit_operator.sh disable_caffeine
# (Re)start the idle inhibitor; it replaces a running copy
~/.config/i3/script/i3_idle_inhibitor.sh &
```

Check that xss-lock runs with the notifier:

```bash
pgrep -a xss-lock    # the output should include: --notifier i3_idle_dim.sh
```

### Test the dimming with xset

Use short timers instead of waiting 10 minutes. Make sure nothing is fullscreen and no
call is running (the idle inhibitor would keep resetting the timer).

```bash
# Dim after 5 s idle, lock 10 s later
xset s 5 10
```

Take your hands off the keyboard and mouse:

- About 5 s: the notification appears and the screens start to fade.
- Move the mouse during the fade: brightness comes back and nothing locks.
- Leave it alone: about 15 s, `i3lock` starts. After unlocking, brightness is normal.

To also see the screen turn off after the lock:

```bash
# Dim at 20 s, lock at 30 s, screen off at 40 s
xset s 20 10 dpms 40 40 40
```

To check only the fade and restore, without the screen saver or a lock:

```bash
~/.config/i3/script/i3_idle_dim.sh    # fades and waits; press Ctrl+C to restore
```

Show the current timers at any time with `xset q` (sections "Screen Saver" and "DPMS").

### Test the idle inhibitor

```bash
xset s 20 10 dpms 40 40 40
```

- Play a video fullscreen (or join a call) and stay idle for a minute: nothing dims or
  locks. Within 30 s, `xset q` shows `DPMS is Disabled`.
- Leave fullscreen (or end the call): within 30 s, `xset q` shows `DPMS is Enabled` again.
- Check whether a program is recording (counts as a call):
  `pactl list source-outputs | grep -E 'Corked|application.name'`

### Restore the normal timing

The short test timers stay until you restore them or log in again:

```bash
~/.config/i3/script/i3_toolkit_operator.sh disable_caffeine
xset q    # Screen Saver: timeout 590 cycle 10; DPMS: Standby 610 Suspend 610 Off 610, Enabled
```

### Tuning

- Fade: at the top of `script/i3_idle_dim.sh`
  - `DIM_BRIGHTNESS=0.3`: how dark the fade ends (1.0 = normal)
  - `FADE_SECONDS=8`: fade length; keep it under the 10 s warning
  - `FADE_STEPS=16`: smoothness (more steps, more `xrandr` calls)
- Timing: `xset s 590 10 dpms 610 610 610` in `script/i3_toolkit_operator.sh`
  (`disable_caffeine`). If you change the warning (`10`), change `WARN_SECONDS` in
  `script/i3_idle_dim.sh` to match. Keep the DPMS time after the lock time.
- Inhibitor: `CHECK_SECONDS=30` in `script/i3_idle_inhibitor.sh`; keep it well below the
  screen saver timeout.

### Troubleshooting

- Screens stay dim (e.g. the dim script was killed with `kill -9`):
  `~/.config/i3/script/i3_idle_dim.sh restore`
- Nothing dims: check `pgrep -a xss-lock` (notifier missing: rerun the setup commands)
  and `xset q` (timeout 0 means Caffeine is on).
- Screen turns off but does not lock: check that DPMS comes after the lock in `xset q`,
  and that the idle inhibitor runs (status view: System mode, then `s`, "Idle inhibitor").
- The fade is a software dim (`xrandr --brightness`); the monitors' backlights stay on.
  A redshift tint is kept.
