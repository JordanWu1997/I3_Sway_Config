# I3WM Configuration Note
Backup note for i3 configuration

Table of Contents
=================

* [I3WM Configuration Note](#i3wm-configuration-note)
   * [Table of Contents](#table-of-contents)
   * [Context](#context)
      * [Display configuration for X-window](#display-configuration-for-x-window)
      * [Lxsession agent](#lxsession-agent)
      * [Hhpc](#hhpc)
      * [Rename workspace](#rename-workspace)
      * [Dmenu](#dmenu)
      * [Master-stack layout](#master-stack-layout)
      * [Auto-name workspace](#auto-name-workspace)
      * [Xcompgr](#xcompgr)
      * [Picom](#picom)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# Context

## Display configuration for X-window

For now, display configuration are all integrated with my script `i3_display_monitor_adopter.sh`

Set output display and primary display (use xrandr command to check) [or use arandr (GUI)]
- Xrandr label
    - \-\-same-as   for mirror mode
    - \-\-right-of  for joint mode
- General setting (arandr GUI)
    - `exec --no-startup-id arandr`
- General setting (xrandr)
    - `exec --no-startup-id xrandr --output HDMI1 --auto --primary --right-of eDP1`
- Setting for my dorm Acer27'
    - `exec --no-startup-id xrandr --output HDMI1 --mode 1920x1080 --primary --right-of eDP1`
- Setting for IOA monitor (24')
    - `exec --no-startup-id xrandr --output HDMI1 --mode 1920x1200 --primary --right-of eDP1`

Set additional display mode for monitor
- Extend mode for HDMI1 (for 16:10 1080P monitor)
    - `exec_always --no-startup-id $I3_SCRIPT/i3_display_operator.sh HDMI1 extend`
- Shrink mode for eDP1 (for better visual consistency with HDMI1)
    - `exec_always --no-startup-id $I3_SCRIPT/i3_display_operator.sh eDP1 shrink`

## Lxsession agent

Load xsession initialization.
For now, this agent will cause mouse left/right button reversed
- Run in i3
    - `exec --no-startup-id lxsession`

## Hhpc

Hide cursor when idle [https://github.com/Aktau/hhpc].
For Fedora, hhpc needs to be complied from source manually.
In i3, hhps conflicts with i3lock since there is no cursor to lock
- Run in i3
    - `exec_always --no-startup-id hhpc -i 3`

## Rename workspace

Rename i3 workspace.
This function conflicts with auto-rename workspace function
- Here use i3-input as input for i3
    - `bindsym Mod4+Shift+w exec i3-input -F "rename workspace to %s" -l 1 -P "New workspace name: "`
- Here use rofi as input for i3
    - `bindsym Mod4+Shift+w exec i3-msg rename workspace to $(rofi -dmenu -lines 0 -width 25 -p "Rename Workspace")`

## Dmenu

Dmenu is i3 built-in selection menu for applications, programs, and etc.
For Fedora, installation: `dnf install dmenu`
There also is the (new) i3-dmenu-desktop which only displays applications
shipping a .desktop file. It is a wrapper around dmenu, so you need dmenu installed.

- Run dmenu (application launcher) in i3
    - ```
      bindsym Mod4+Shift+Return exec --no-startup-id dmenu_run -l 16 \
        -fn "DroidSansMono Nerd Font 16" -p "Dmenu [Program Launcher]" \
        -nb "$bg" -nf "$c1" -sb "$c3" -sf "$fg"
        ```

- Run i3-dmenu-desktop in i3

    - ```
      bindsym Mod4+Shift+Return exec --no-startup-id i3-dmenu-desktop \
        --dmenu="dmenu -fn 'pango:DroidSansMono Nerd Font 16' -l 10 -p 'Program launcher'"
        ```

## Master-stack layout

Add master-stack layout to i3 [https://github.com/windwp/i3-master-stack]
The master-stack mode conflicts with both i3_automark.py, autotiling.
They must be DISABLED first.

- Installation
    - `cd ~/.config/i3/; git clone https://github.com/windwp/i3-master-stack.git`
- Run in i3
    - `exec_always --no-startup-id $HOME/.config/i3/i3-master-stack/i3_master`

Master-stack layout keybindings
- Swap to master node
    - `bindsym Mod4+semicolon nop swap master`
- Go to master node
    - `bindsym Mod4+m nop go master`
-  Enable/disable master layout in current workspace
    - `bindsym $mod+alt+m nop master toggle`

## Auto-name workspace
Auto-name workspace name with fancy symbols [https://github.com/cboddy/i3-workspace-names-daemon].
For fancy symbols support, NERD font must be installed first.
Symbols can be user-defined in `$HOME/.config/i3/share/app-icons.json`.

- Run in i3
    - `exec --no-startup-id $PYTHON_BIN/i3-workspace-names-daemon -config-path $HOME/.config/i3/share/app-icons.json`

## Xcompgr
X-window compositor for transparency support (now use picom instead)
But it works better in low-resource computer (e.g virtual machine)

- Run in i3
    - `exec --no-startup-id xcompmgr -c -f -n`

## Picom
X-window compositor for animation, transparency, blur support [https://man.archlinux.org/man/picom.1.en].
For now, picom function has been integrated in my `$HOME/.config/i3/script/i3_display_monitor_adopter.sh script)`.
Unfortunately, picom in Fedora repository not work well [https://github.com/yshui/picom],
so I use picom fork of jonaburg [https://github.com/jonaburg/picom] instead (need manually installed on Fedora)

- Run in i3
    - `exec_always --no-startup-id /usr/local/bin/picom --config $HOME/.config/picom/picom_blur.conf`
