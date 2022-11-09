# Sway_Config
My SwayWM configuration files

# Context
- For now, the configuration files are copied from my I3WM
- But there are still tons of work to fully migrated to SwayWM

## Configuration Migration to SwayWM

| Configuration           | Description      | Migration Progress | Note |
| :---------------------: | :--------------: | :----------------: | :--: |
| `sway_bar.config`       | Bar              | 0%                 |      |
| `sway_bindkey.config`   | Keybinding       | 0%                 |      |
| `sway_custom.config`    | Customization    | 0%                 |      |
| `sway_gap.config`       | Gap              | 100%               |      |
| `sway_mode.config`      | Mode usage       | 0%                 |      |
| `sway_startup.config`   | Startup programs | 0%                 |      |
| `sway_window.config`    | Window/Container | 0%                 |      |
| `sway_workspace.config` | Workspace        | 0%                 |      |


## Problems
- SwayWM do not load my `~/.profile` file (that stores environmental variables) at startup
- Cannot find `pywal` alternatives for SwayWM
- Migrate `i3-msg` to `sway-msg` (maybe use symbolic links? i3-msg -> sway-msg)

### Programs Need Wayland Alternatives

| X Program           | Wayland Alternative | Note |
| :-----------------: | :-----------------: | :--: |
| `arandr`            |                     |      |
| `autotiling`        |                     |      |
| `conky`             |                     |      |
| `dunst`             |                     |      |
| `feh`               |                     |      |
| `i3-ipc`            |                     |      |
| `i3-msg`            | `sway-msg`          |      |
| `i3-workspace-swap` |                     |      |
| `i3_automark.py`    |                     |      |
| `i3_resurrect`      |                     |      |
| `parcellite`        |                     |      |
| `pywal`             |                     |      |
| `rofi`              |                     |      |
| `unclutter`         |                     |      |
| `xbacklight`        |                     |      |
| `xdotool`           |                     |      |
| `xrandr`            |                     |      |
| `xscreensaver`      |                     |      |
