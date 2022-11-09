# I3_Sway_Config
Backup for my configuration of __i3WM (X11)__ and __SwayWM (Wayland)__,
and configurations of applications for the working environment in X11/Wayland.
For now, some functions do not work in Wayland, still searching for solutions or alternatives in Wayland.
For more SwayWM details and i3WM migration progress, please check `.config/sway/README.md`

Table of Contents
=================
<details open>
<summary>Click to expand/shrink</summary>

* [I3_Sway_Config](#i3_sway_config)
* [Table of Contents](#table-of-contents)
* [Context](#context)
   * [Section 1 - Demo Current Customization](#section-1---demo-current-customization)
      * [Features in My Configuration](#features-in-my-configuration)
   * [Section 2 - Details of i3 Environment](#section-2---details-of-i3-environment)
      * [1. My i3 Environment](#1-my-i3-environment)
      * [2. Programs Auto-start in Background for i3 Environment](#2-programs-auto-start-in-background-for-i3-environment)
      * [3. Wallpapers](#3-wallpapers)
      * [4. Theme and Fonts](#4-theme-and-fonts)
   * [Section 3 - First Time Usage for i3](#section-3---first-time-usage-for-i3)
      * [1. Configuration distributor](#1-configuration-distributor)
      * [2. Optional Configuration](#2-optional-configuration)
   * [Section 4 - Mode Usage for i3](#section-4---mode-usage-for-i3)
      * [1. Mode Usage](#1-mode-usage)
   * [Section 5 - Mouse Usage for i3](#section-5---mouse-usage-for-i3)
      * [1. Touchpad Usage](#1-touchpad-usage)
      * [2. Mouse Usage](#2-mouse-usage)
   * [Section 6 - Keybinding Sheet for i3](#section-6---keybinding-sheet-for-i3)
      * [1. Prefix: Winkey](#1-prefix-winkey)
      * [2. Prefix: Winkey + Shift](#2-prefix-winkey--shift)
      * [3. Prefix: Ctrl + Alt](#3-prefix-ctrl--alt)
      * [4. Miscellaneous](#4-miscellaneous)
   * [Reference for i3 Setup](#reference-for-i3-setup)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

</details>

# Context
<details open>
<summary>Click to expand/shrink</summary>

## Section 1 - Demo Current Customization
<details open>
<summary>Click to expand/shrink</summary>

![alt text](./demo/MY_I3WM_WAL_DEMO_03.png "Title")
![alt text](./demo/MY_I3WM_WAL_DEMO_05.png "Title")

### Features in My Configuration
Note: the term "window" used in this configuration actually refers to "container" in i3 window manager

- [x] __Dwindle Layout__: auto-split window in long-side. (Check [Section 2](#section-2---details-of-i3-environment))
- [x] __Window Auto-mark__: auto-mark window for moving/swapping. (Check [Section 2](#section-2---details-of-i3-environment))
- [x] __Pywal Integration__: change color theme based on wallpaper. (Check [Section 2](#section-2---details-of-i3-environment))
- [x] __Keyboard-driven Working Environment__: (Check [Section 2](#section-2---details-of-i3-environment))
- [x] __Customized Rofi__: easy-to-use selector/launcher. (Check [Section 2](#section-2---details-of-i3-environment))
- [x] __Customized Conky__: system monitor and keybinding hinter. (Check [Section 2](#section-2---details-of-i3-environment))
- [x] __Configuration Distributor Script__: script to apply this configuration. (Check [Section 3](#section-3---first-time-usage-for-i3))
- [x] __Various Mode Usage__: organize related functions into modes to keep keybindings simple. (Check [Section 4](#section-4---mode-usage-for-i3))
- [x] __Mouse/Trackpad Usage__: empower mouse/trackpad to do more things. (Check [Section 5](#section-5---mouse-usage-for-i3))
- [x] __Fully Documented Keybinding and i3-userguide-like Cheat sheet__: (Check [Section 6](#section-6---keybinding-sheet-for-i3))
- [ ] __Workflow Demo__: theme changing, mode usage, keyboard-driven workflow (Check [My workflow note](https://github.com/JordanWu1997/Knowlodge_Base/blob/main/workflow/My_Frequently_Used_Program_Shortcuts.md))
- [ ] __Configuration Documentation__: Document my configuration setup details in `./config.d`

</details>

### My Workflow Demo

## Section 2 - Details of i3 Environment
<details>
<summary>Click to expand/shrink</summary>

### 1. My i3 Environment
<details open>
<summary>Click to expand/shrink</summary>

- Display Manager: [GNOME display manager (GDM)](https://gitlab.gnome.org/GNOME/gdm)
- i3 Window Manager: [i3-gap](https://github.com/Airblader/i3) `4.20.1`
- Status Bar: [i3bar](https://i3wm.org/docs/userguide.html#_configuring_i3bar) `4.20.1` + [bumblebee-status](https://github.com/tobi-wan-kenobi/bumblebee-status) `2.0.5`
- Terminal: [kitty](https://github.com/kovidgoyal/kitty) `0.25.0`
- Shell: [fish](https://github.com/fish-shell/fish-shell) `3.4.1` + [oh-my-fish](https://github.com/oh-my-fish/oh-my-fish) `7` + [starship](https://starship.rs/) `1.2.1`
- Terminal Multiplexer: [tmux](https://github.com/tmux/tmux) `3.2a` + [my configuration](https://github.com/JordanWu1997/Vim_Tmux_Config)
- Text Editor: [neovim](https://github.com/neovim/neovim) `0.6.1` + [my configuration](https://github.com/JordanWu1997/Vim_Tmux_Config)
- Application Launcher: [rofi](https://github.com/davatorium/rofi) `1.7.3`
- Theme Configurer: [pywal](https://github.com/dylanaraps/pywal) `3.3.1`
- GTK Theme Changer: [lxappearance](https://github.com/lxde/lxappearance)
- Qt/KDE Theme Change: [Kvantum](https://github.com/tsujan/Kvantum)
- X Compositor: [picom](https://github.com/jonaburg/picom) `vgit-a8445`
- Notification Daemon: [dunst](https://github.com/dunst-project/dunst) `1.8.0`
- GUI File Manager: [Nautilus](https://gitlab.gnome.org/GNOME/nautilus)
- TUI File Manager: [ranger](https://github.com/ranger/ranger) `1.9.3`
- Web Browser: [Brave browser](https://brave.com/) + [vimium](https://vimium.github.io/)
- PDF viewer: [zathura](https://github.com/pwmt/zathura) + [zathura-pywal](https://github.com/GideonWolfe/Zathura-Pywal)

</details>

### 2. Programs Auto-start in Background for i3 Environment
<details open>
<summary>Click to expand/shrink</summary>

- [xrandr](https://www.x.org/wiki/Projects/XRandR/): multi-monitor window arrangement
- [pywal](https://github.com/dylanaraps/pywal): color theme autotune by wal
- [feh](https://github.com/derf/feh): image viewer, wallpaper changer
- [conky](https://github.com/brndnmtthws/conky): system monitor for X window
- [polkit-gnome](https://fedora.pkgs.org/33/fedora-x86_64/polkit-gnome-0.106-0.7.20170423gita0763a2.fc33.x86_64.rpm.html): GUI software authentication support
- [NetworkManger](https://fedoraproject.org/wiki/Tools/NetworkManager): network manager
- [blueman](https://fedoraproject.org/wiki/Features/Blueman): bluetooth manager
- [imwheel](http://imwheel.sourceforge.net/): mouse speed manager
- [ibus-chewing](https://github.com/definite/ibus-chewing): input method for chewing
- [xss-lock](https://bitbucket.org/raymonad/xss-lock/src/master/): X session lock
- [parcellite](https://github.com/rickyrockrat/parcellite): clipboard applet
- [flashfocus](https://github.com/fennerm/flashfocus): flash when changing focus
- [dunst](https://github.com/dunst-project/dunst): notification daemon
- [kdeconnectd](https://community.kde.org/KDEConnect): mobile phone connector
- [bumblebee-status](https://github.com/tobi-wan-kenobi/bumblebee-status): i3 status bar information support
- [rjekker/i3-battery-popup](https://github.com/rjekker/i3-battery-popup): battery warning for laptop
- [lincheney/i3_automark.py](https://github.com/lincheney/i3-automark/blob/master/i3-automark.py): auto-mark i3 window (with preset mark)
- [nwg-piotr/autotiling.py](https://github.com/nwg-piotr/autotiling): auto-tile i3 container (Horizontal -> Vertical -> Horizontal -> ...)
- [jonaburg/picom](https://github.com/jonaburg/picom): X compositor for blur, transparency, animation support
- [Airblader/unclutter-xfixes](https://github.com/Airblader/unclutter-xfixes): auto-hide mouse cursor

</details>

### 3. Wallpapers
<details open>
<summary>Click to expand/shrink</summary>

- Fedora 33/34 Built-in Logo: [Logos](https://en.wikipedia.org/wiki/Fedora_(operating_system))
- Default Wallpapers: [Arc Dark Fedora Wallpaper](https://www.reddit.com/r/Fedora/comments/8zji6j/by_request_clean_and_simple_arc_dark_fedora/)
- Default Lock Screen Wallpaper: [Thinkpad Trackpoint Wallpaper](https://www.wallpaperflare.com/thinkpad-lenovo-full-frame-close-up-no-people-pattern-indoors-wallpaper-hivip)
- [Optional] More Wallpapers from dt: [Wallpapers](https://gitlab.com/dwt1/wallpapers)

</details>

### 4. Theme and Fonts
<details open>
<summary>Click to expand/shrink</summary>

- Theme: [Arc-Dark-solid](https://github.com/horst3180/arc-theme)
- Icon: [Papirus dark](https://www.gnome-look.org/p/1166289/)
- GUI Font: [SAN regular](https://fonts.google.com/specimen/Open+Sans)
- TUI Font: [DroidSansMono Nerd Font Bold](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete%20Mono.otf)

</details>
</details>

## Section 3 - First Time Usage for i3
<details>
<summary>Click to expand/shrink</summary>

### 1. Configuration distributor
<details open>
<summary>Click to expand/shrink</summary>

- Run distributor in this git repository `./config/i3/script/i3_config_distributor.sh`
- Includes
    - __Add Environment Variables__
        - Add `I3_SCRIPT` to `$PATH` in `$HOME/.profile`
        - Add `I3_SCRIPT` in `$HOME/.profile`
        - Add `WALLPAPERI3` in `$HOME/.profile`
    - __Backup Old Configuration and Link New Configuration__
        - Backup old configuration file `$HOME/.config/*` to `$HOME/.config_backup` directory
        - Link configuration in git repository `./config/*` to `$HOME/.config` directory
    - __Install Programs for Work Environment__

</details>

### 2. Optional Configuration
<details open>
<summary>Click to expand/shrink</summary>

- [Optional] Add following lines for pywal color support for bash/zsh/fish, NO NEED for kitty terminal emulator
    ```
    #Add following line to .bashrc/.zshrc/config.fish
    [ -f {$HOME}/.cache/wal/sequences ] && /usr/bin/cat {$HOME}/.cache/wal/sequences
    ```

</details>
</details>

## Section 4 - Mode Usage for i3
<details>
<summary>Click to expand/shrink</summary>

- i3 has a built-in mode function that overwrites current keybinding with preset mode keybinding
- When i3 mode is on, mode keybinding instruction shows on the i3 status bar
- Press `[Esc]` or `[Ctrl]`+`[[]` (vim-style escape) to exit mode
- Press `[Enter]` to go to the last level of mode and exit mode if it is already the last one
- This part configuration can be found in
    - `./config/i3/config.d/i3_mode.config`
    - `./config/i3/config.d/i3_custom.config`
    - `./config/i3/config.d/i3_bar.config`
    - `./config/i3/config.d/i3_gap.config`

### 1. Mode Usage
<details open>
<summary>Click to expand/shrink</summary>

- __Insert Mode (`[Winkey]` + `[Shift]` + `[i]`)__
    - Disable i3 keybindings. Press `[Ctrl]`+`[[]` to get i3 keybindings back
- __Vim Keybinding Mode (`[Winkey]` + `[Ctrl]` + `[[]`)__
    - Enable vim keybindings for navigation, e.g. h/j/k/l. Press `[Ctrl]` + `[[]` to exit mode
- __System Mode (`[Winkey]` + `[Shift]` + `[Esc]`)__
    - System command, e.g. exit, power off, reboot, lock, hibernate, caffeine function
- __Display Mode (`[Winkey]` + `[Shift]` + `[x]`)__
    - Deal with multiple monitor configuration, e.g. joint monitor, mirror monitor
- __Backlight Mode (`[Ctrl]`+`[Alt]`+`[x]`)__
    - Modify monitor backlight level
- __Redshift Mode (`[Winkey]` + `[Shift]` + `[z]`)__
    - Screen color temperature tuner
- __Dunst Mode (`[Winkey]` + `[Shift]` + `[v]`)__
    - Dunst actions, including stopping or resuming dunst
- __Mouse Mode (`[Ctrl]` + `[Alt]` + `[m]`)__
    - Mouse emulator using keyboard, e.g. move, left/right click, cursor auto-hide
- __Resize Mode (`[Ctrl]` + `[Alt]` + `[r]`)__
    - Resize focused window
- __Gap Mode (`[Winkey]` + `[Shift]` + `[g]`)__
    - Modify i3 gaps, e.g. inner gaps, outer gaps
- __Bar Mode (`[Winkey]` + `[Shift]` + `[b]`)__
    - Show/hide i3bar, reload i3bar, set default bar options (e.g. mode, position, fontsize)
- __Title Bar Mode (`[Winkey]` + `[Shift]` + `[t]`)__
    - Modify i3 title bar, e.g. hide/show title bar, font size
- __Player Mode (`[Ctrl]`+`[Alt]`+`[p]`)__
    - Player control (e.g. previous, pause-play, next, fast/back-ward, stop) for spotifyd, player, vlc
- __Spotifyd Mode (`[Ctrl]`+`[Alt]`+`[s]`)__
    - Spotifyd control (e.g. enable, disable, reload) for spotifyd
- __Volume Mode (`[Ctrl]`+`[Alt]`+`[v]`)__
    - Volume control with pulsemixer (e.g. volume up/down, mute)
- __Mark Mode (`[Winkey]` + `[Shift]` + `[m]`)__
    - Mark window, go to/swap marked window, auto-mark function
- __Window Layout Mode (`[Winkey]` + `[Shift]` + `[w]`)__
    - Change i3 window layout, e.g. tiling, tabbed, stacking mode, auto-tiling function
- __Workspace Mode (`[Winkey]` + `[Shift]` + `[p]`)__
    - Manipulate i3 workspace, e.g. swap, save, restore
        - __Swap Workspace Mode (`[p]`)__
            - Swap workspace
        - __Save Workspace Mode (`[s]`)__
            - Save workspace layout
        - __Restore Workspace Mode (`[r]`)__
            - Restore workspace layout
- __Customization Mode (`[Winkey]` + `[Shift]` + `[c]`)__
    - Customize i3wm, e.g. wallpaper, theme, X compositor
        - __Border Mode (`[b]`)__
            - Window container border width, color scheme and edge border option
        - __Conky Mode (`[c]`)__
            - System monitor, i3 keybinding sheet, conky color palette
        - __Picom Mode (`[p]`)__
            - Blur, transparency support
        - __Flashfocus Mode (`[f]`)__
            - Flash window with additional filter provided by picom (overlay picom settings)
        - __Theme Mode (`[t]`)__
            - Auto-theme with pywal and reload applications after auto-theming
        - __Wallpaper Mode (`[w]`)__
            - Select wallpaper, set default wallpaper
        - __Variety Mode (`[v]`)__
            - Variety wallpaper selector, set default wallpaper

</details>
</details>

## Section 5 - Mouse Usage for i3
<details>
<summary>Click to expand/shrink</summary>

- Although the keyboard-driven workflow is favored in i3, there is no harm in keeping mouse function
- This part of configuration can be found in
    - `./config/i3/config.d/i3_bindkey.config`
    - `./config/i3/config.d/i3_mode.config`

### 1. Touchpad Usage
<details open>
<summary>Click to expand/shrink</summary>

- __2-finger Gesture__
    - __Tap__
        - Right key click
    - __Swipe__
        - Scroll
- __3-finger Gesture__
    - __Tap__
        - Middle key click
    - __Swipe Up__
        - Toggle window full-screen mode
    - __Swipe Down__
        - Toggle floating mode
    - __Swipe Left__
        - Go to previous workspace
    - __Swipe Right__
        - Go to next workspace
- __4-finger Gesture__
    - __Pinch Out__
        - Bring window in scratchpad (background workspace) to foreground
    - __Pinch In__
        - Send window to scratchpad (background workspace)

</details>

### 2. Mouse Usage
<details open>
<summary>Click to expand/shrink</summary>

- __Middle Key__
    - __Click Title Bar__
        - Kill current window
    - __`[Winkey]` + Click anywhere except title bar__
        - Kill current window
- __Right Key__
    - __Click Title Bar__
        - Toggle floating mode
    - __`[Winkey]` + Click anywhere except title bar__
        - Toggle floating mode
- __Scroll Wheel__
    - __Scroll Up/Down Border__
        - Show/Hide title bar

</details>
</details>

## Section 6 - Keybinding Sheet for i3
<details>
<summary>Click to expand/shrink</summary>

- Cheat sheet format, color theme here is the same as the i3 user guide
- It is __HIGHLY RECOMMENDED__ to change `caplocks` to `ctrl` for your little finger (default in this configuration)
    - `caplocks` can be remapped to `ctrl` with following command in shell
        ```bash
        setxkbmap -option "ctrl:nocaps"
        ```
    - The remapping command will be automatically activated as you enter i3
        - Check `./config/i3/config.d/i3_startup.config`
- All following keybindings can be configured in
    - `./config/i3/config.d/i3_bindkey.config`
    - `./config/i3/config.d/i3_workspace.config`
    - `./config/i3/config.d/i3_custom.config`
    - `./config/i3/config.d/i3_gap.config`
    - `./config/i3/config.d/i3_mode.config`
    - `./config/i3/config.d/i3_bar.config`

### 1. Prefix: Winkey
<details open>
<summary>Click to expand/shrink</summary>

![alt text](./demo/Shortcut_Sheet/i3_shortcut_win.png "Title")
- __Go to workspace (`[Winkey]`+[`1`~`9`, `0`])__

</details>

### 2. Prefix: Winkey + Shift
<details open>
<summary>Click to expand/shrink</summary>

![alt text](./demo/Shortcut_Sheet/i3_shortcut_win_shift.png "Title")
- __Send window to workspace (`[Winkey]`+`[Shift]`+[`1`~`9`, `0`])__

</details>

### 3. Prefix: Ctrl + Alt
<details open>
<summary>Click to expand/shrink</summary>

![alt text](./demo/Shortcut_Sheet/i3_shortcut_ctrl_alt.png "Title")
- __Program shortcut (`[Ctrl]`+`[Alt]`+[`1`~`9`,`0`,`-`,`=`])__
    - `1`: [Neovim (text editor)](https://neovim.io/)
    - `2`: [Ranger (file manager)](https://github.com/ranger/ranger)
    - `3`: [Pulsemixer (audio manager)](https://pypi.org/project/pulsemixer/)
    - `4`: [Htop (system monitor)](https://htop.dev/)
    - `5`: [Nmtui (network manager)](https://developer.gnome.org/NetworkManager/stable/nmtui.html)
    - `6`: [Cava (audio visualizer)](https://github.com/karlstav/cava)
    - `7`: [Spt (spotify-tui)](https://github.com/Rigellute/spotify-tui)
    - `8`: [Zathura (document viewer)](https://github.com/pwmt/zathura)
    - `9`: [Blueman (bluetooth manager)](https://github.com/blueman-project/blueman)
    - `0`: [Nautilus (GUI file manager)](https://wiki.gnome.org/action/show/Apps/Files?action=show&redirect=Apps%2FNautilus)
    - `-`: [Brave browser (web browser)](https://brave.com/)
    - `=`: [Firefox (web browser)](https://www.mozilla.org/en-US/firefox/)
- __Program in floating mode shortcut (`[Ctrl]`+`[Alt]`+`[Shift]`+[`1`~`7`])__

</details>

### 4. Miscellaneous
<details open>
<summary>Click to expand/shrink</summary>

- __Go to Workspace (Absolutely)__
    - `[Winkey]` + `[Number(#)]`: Go to workspace number # (A#) in monitor 1 (eDP1)
    - `[Winkey]` + `[Function(F#)]`: Go to workspace number 10+# (B#) in monitor 2 (HDMI1)
    - `[Ctrl]` + `[Function(F#)]`: Go to workspace number 20+# (C#) in monitor 3 (VIRTUAL1)
    - `[Alt]` + `[Function(F#)]`: Go to workspace number 30+# (D#) in monitor 4 (VIRTUAL2)
- __Go to Workspace (Relatively)__
    - `[Winkey]` + (`[Shift]`) + `[Tab]`: Go to (prev)/next existing workspace
    - `[Winkey]` + (`[Shift]`) + `[Grave]`: Go to (prev)/next workspace (create one if it does not exist)
    - `[Winkey]` + `[Alt]` + (`[Shift]`) + `[Tab]`: Create and go to (prev)/next free workspace
    - `[Winkey]` + `[Ctrl]` + `[Tab]`: Go to next workspace back and forth
    - `[Ctrl]` + `[Alt]` + `[Left/Right]`: Gnome-like workspace operation. Move to (prev)/next existing workspace (create one if it does not exist)
- __Swap Workspace (Relatively)__
    - `[Winkey]` + (`[Shift]`) + `[Ctrl]` + `[Grave]`: Swap current workspace with (prev)/next workspace (create one if it does not exist)
- __Send Window to Workspace (Absolutely)__
    - `[Winkey]` + `[Shift]` + `[Number(#)]`: Send window to workspace number # (A#) in monitor 1 (eDP1), Note: max # is 10
    - `[Winkey]` + `[Shift]` + `[Function(F#)]`: Send window to workspace number 10+# (B#) in monitor 2 (HDMI1), Note: max # is 10
    - `[Ctrl]` + `[Shift]` + `[Function(F#)]`: Send window to workspace number 20+# (C#) in monitor 3 (VIRTUAL1), Note: max # is 10
    - `[Alt]` + `[Shift]` + `[Function(F#)]`: Send window to workspace number 30+# (D#) in monitor 4 (VIRTUAL2), Note: max # is 10
- __Send Window to Workspace (Relatively)__
    - `[Alt]` + (`[Shift]`) + `[Grave]`: Send window to (prev)/next existing workspace
    - `[Winkey]` + `[Alt]` + (`[Shift]`) + `[Grave]`: Send window to (prev)/next free workspace
    - `[Ctrl]` + `[Alt]` + `[Shift]` + `[Left/Right]`: Gnome-like workspace operation. Send to prev/next workspace (create one if it does not exist)
- __List Windows__
    - `[Alt]` + `[Tab]`: List all windows on all workspaces (Windows-like keybinding)
- __Manipulate Scratchpad__
    - `[Winkey]` + `[-]`: Send focused window to the scratchpad (background workspace)
    - `[Winkey]` + `[Shift]` + `[-]`: Send all floating windows to scratchpad (background workspace)
    - `[Winkey]` + `[=]`: Bring window in scratchpad to foreground one by one
    - `[Winkey]` + `[Shift]` + `[=]`: Bring all windows in scratchpad to foreground
- __Change Gap Size__
    - `[Ctrl]` + `[Alt]` + `[Shift]` + `[h/l]`: Decrease/Increase horizontal outer gap size
    - `[Ctrl]` + `[Alt]` + `[Shift]` + `[j/k]`: Decrease/Increase vertical outer gap size
    - `[Ctrl]` + `[Alt]` + `[Shift]` + `[m/p]`: Decrease/Increase inner gap size
    - `[Ctrl]` + `[Alt]` + `[Shift]` + `[o]`: Restore to default outer gap size
    - `[Ctrl]` + `[Alt]` + `[Shift]` + `[i]`: Restore to default inner gap size
- __Screenshot__
    - `[PrtSc]`: Flameshot (screenshot tool)
    - `[Winkey]` + `[PrtSc]`: Gnome-screenshot for the current window
    - `[Winkey]` + `[Shift]` + `[PrtSc]`: Gnome-screenshot interactive mode

</details>
</details>

## Reference for i3 Setup
<details>
<summary>Click to expand/shrink</summary>

- https://i3wm.org/docs/userguide.html
- https://wiki.archlinux.org/title/I3
- https://github.com/Airblader/i3 (i3-gap)
- https://github.com/levinit/i3wm-config (written in Chinese)
- https://www.itread01.com/p/142448.html (written in Chinese)
- https://segmentfault.com/a/1190000022083424 (written in Chinese)
- https://github.com/alberto-santini/i3-configuration-x1
- https://pypi.org/project/i3-resurrect/
- https://pypi.org/project/i3-workspace-swap/
- https://github.com/rjekker/i3-battery-popup
- https://github.com/lincheney/i3-automark
- https://www.youtube.com/watch?v=j1I63wGcvU4&list=PL5ze0DjYv5DbCv9vNEzFmP6sU7ZmkGzcf
- https://regolith-linux.org/
- https://arcolinux.com/

</details>
