# Sway_Config

My SwayWM (Wayland) configuration, converted from my i3 configuration in `../i3`.

**Status: migrated.** Tested on Ubuntu 24.04 with sway 1.9. Everything that works on i3
works here, except the items listed in `doc/00_MIGRATION_OVERVIEW.md` ("What could NOT be
fully converted"). Start with `doc/06_MIGRATION_PROCESS.md` and
`doc/07_I3_SWAY_CORRESPONDENCE.md`.

# Table of Contents

- [Context](#context)
  - [config.d](#configd)
  - [script](#script)
  - [bin](#bin)
  - [share](#share)
  - [doc](#doc)
- [Quick start](#quick-start)

# Context

The sway configuration mirrors the i3 configuration file by file. Every difference from
i3 is marked in the files with a `[SWAY]` comment. The conversion is recorded in `doc/`.

## config.d

| File | Content |
| :-- | :-- |
| `sway_input_output.config` | **sway-only.** Outputs, keyboard (xkb), pointer, touchpad, cursor hiding, gestures |
| `sway_mode_name.config` | **sway-only.** All `set $mode_*` labels (must load before any binding, see doc/01) |
| `sway_window.config` | Window/container settings, colors, for_window rules (class + app_id) |
| `sway_workspace_name.config` | Workspace names (included before `sway_workspace.config`) |
| `sway_workspace.config` | Workspace settings and bindings |
| `sway_gap.config` | Gaps |
| `sway_bindkey.config` | Keybindings |
| `sway_mode.config` | Modes |
| `sway_custom.config` | Wallpaper, theme, opacity (picom replacement), conky, dunst, fonts |
| `sway_bar.config` | swaybar + bumblebee-status |
| `sway_startup.config` | Startup programs |
| `sway_iOS_compatibility.config` | iOS keyboard (Mod4 → Mod5) compatibility |

## script

Wayland ports of the X11-dependent i3 scripts (`sway_*.sh`), plus sway-only helpers.
Scripts that only use i3 IPC (`i3-msg`, python `i3ipc`) are **shared** from
`~/.config/i3/script` (`$I3_SCRIPT`). This works because sway exports `I3SOCK`.

## bin

`bin/ueberzug`: inside sway only, sends ranger's image previews to ueberzugpp with its native
Wayland output. Outside sway it passes through to the normal ueberzug.

## share

| File | Content |
| :-- | :-- |
| `colors-sway-fallback` | Fallback palette (the i3 `set_from_resource` fallbacks) |
| `wal_templates/colors-sway-i3` | pywal user template → `~/.cache/wal/colors-sway-i3` |
| `sway-session.desktop` | Login-manager entry that starts `sway-session` |
| `sway-portals.conf` | xdg-desktop-portal backend routing (screen sharing via -wlr) → `~/.config/xdg-desktop-portal/` |

Wallpapers, icons and the automark list stay in `~/.config/i3/share`, shared by both WMs.

## doc

| Report | Content |
| :-- | :-- |
| `doc/00_MIGRATION_OVERVIEW.md` | Start here: summary, checklist, everything that could not be converted |
| `doc/01_CONFIG_CONVERSION.md` | Line-level conversion record per config file |
| `doc/02_SCRIPT_PORTING.md` | Script porting index (details in `doc/migration/`) |
| `doc/03_X11_TO_WAYLAND_CHANGES.md` | What must change when moving from X11 to Wayland |
| `doc/04_XWAYLAND_APP_COVERAGE.md` | XWayland compatibility and coverage of my application selection |
| `doc/05_PACKAGES_AND_INSTALL.md` | Package mapping and the install script |
| `doc/06_MIGRATION_PROCESS.md` | How the migration was done and tested, lessons, how to maintain both configs |
| `doc/07_I3_SWAY_CORRESPONDENCE.md` | i3 ↔ sway application and script correspondence, with the differences |

# Quick start

```bash
./installation/install_sway.sh           # packages + links + login entry
swaymsg -t get_outputs                   # (inside sway) then fix $monitor1..5 in config
sway -C -c ~/.config/sway/config         # validate the config
```

At the login screen, pick **"Sway"** or **"Sway (user session)"**. The installer makes both start
`sway-session`, which loads `~/.profile` and the input-method variables, and handles the
NVIDIA driver.

Useful defaults in `config` (edit, then Mod+Shift+r):

| Variable | Values | Default |
| :-- | :-- | :-- |
| `$default_input_method` | `fcitx5` / `ibus` | `fcitx5` (Ctrl+Alt+space toggles English ↔ chewing) |
| `$default_screenshot_tool` | `grim` / `flameshot` | `grim` (grim + slurp + satty/swappy) |

Troubleshooting: `script/sway_session_check.sh`, `script/sway_input_method.sh doctor`,
`$XDG_RUNTIME_DIR/sway_screenshot.log`, `~/.local/state/sway.log`.
