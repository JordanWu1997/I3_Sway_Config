# I3_Sway_Config
Backup for my I3WM (Xorg) and Sway (Xwayland) configuration

## Preparation (Dependence)
1. Software list
- Shell: [fish](https://github.com/fish-shell/fish-shell) + [oh-my-fish](https://github.com/oh-my-fish/oh-my-fish)
- Terminal: [kitty](https://github.com/kovidgoyal/kitty)
- Launcher: [rofi](https://github.com/davatorium/rofi)
- Theme configurator: [pywal](https://github.com/dylanaraps/pywal)
- Xcompositor: [picom](https://github.com/jonaburg/picom)
- Notification: [dunst](https://github.com/dunst-project/dunst)
- Status Bar: [default i3bar](https://i3wm.org/docs/userguide.html#_configuring_i3bar) + [bumblebee-status](https://github.com/tobi-wan-kenobi/bumblebee-status)
- Text Editor: [neovim](https://github.com/neovim/neovim) + [my configuration](https://github.com/JordanWu1997/Vim_Tmux_Config)

2. Wallpapers
- Default Wallpapers: [Arc Dark Fedora Wallpaper](https://www.reddit.com/r/Fedora/comments/8zji6j/by_request_clean_and_simple_arc_dark_fedora/)
- Default Lockscreen wallpaper: [Thinkpad Trackpoint Wallpaper](https://www.wallpaperflare.com/thinkpad-lenovo-full-frame-close-up-no-people-pattern-indoors-wallpaper-hivip)
- [Optional] More wallpapers from dt: [Wallpapers](https://gitlab.com/dwt1/wallpapers)
- [Optional] Fedora 33/34 built-in logo: [Logos](https://en.wikipedia.org/wiki/Fedora_(operating_system))

## First Time Usage
1. $HOME/.profile (PATH/VARIABLES)
- Add PATH and I3_BIN to ~/.profile
```
# Add following lines to ~/.profile
export PATH=$HOME/.config/i3/bin:$PATH
export PATH=$HOME/.local/bin:$PATH
export I3_BIN=$HOME/.config/i3/bin
```

2. $HOME/.config (CONFIGURATION)
- Link/copy config directories/files under ~/.config
```
# Link or copy following lines to ~/.config
# If is already a config file in ~/config, remove it first
cd ~/.config/ && rm -fr i3 kitty dunst ranger rofi picom bumblebee-status vis conky
ln -s ~/Desktop/I3_Sway_Config/config/i3
ln -s ~/Desktop/I3_Sway_Config/config/kitty/
ln -s ~/Desktop/I3_Sway_Config/config/dunst
ln -s ~/Desktop/I3_Sway_Config/config/ranger
ln -s ~/Desktop/I3_Sway_Config/config/rofi
ln -s ~/Desktop/I3_Sway_Config/config/picom
ln -s ~/Desktop/I3_Sway_Config/config/bumblebee-status
ln -s ~/Desktop/I3_Sway_Config/config/vis
ln -s ~/Desktop/I3_Sway_Config/config/conky
```

### 3. $HOME/dotfile (SHELL CONFIGURATION)
- Add following lines for pywal color support for bash/zsh/fish
```
# Add following line to .bashrc/.zshrc/config.fish
[ -f {$HOME}/.cache/wal/sequences ] && /usr/bin/cat {$HOME}/.cache/wal/sequences
```

## Autostart Programs
- xrandr
- wal
- gnome-authentication-agent
- NetworkManger
- bluetooth
- numlockx
- imwheel
- ibus
- parcellite
- flashfocus
- dunst
- kdeconnectd
- battery-popup
- i3_automark
- xss-lock
- picom

## Keybinding Sheet
- Workspace
- Container
- I3 built-in

## Mode Usage
- System mode
- Gap mode
- Titlebar mode
- Mark mode
- Picom mode
- Mouse mode
- Display mode
- Redshift mode
- Resize mode
- Theme mode
- Wallpaper mode

## Reference
- https://i3wm.org/docs/userguide.html
- https://github.com/levinit/i3wm-config
- https://www.itread01.com/p/142448.html
- https://medium.com/@mudrii/archlinux-tutorial-part-3-i3-configuration-and-op
- https://github.com/alberto-santini/i3-configuration-x1
- https://segmentfault.com/a/1190000022083424
- https://github.com/Airblader/i3 (i3-gap)
- https://pypi.org/project/i3-resurrect/
- https://pypi.org/project/i3-workspace-swap/
- https://github.com/rjekker/i3-battery-popup
- https://github.com/lincheney/i3-automark
