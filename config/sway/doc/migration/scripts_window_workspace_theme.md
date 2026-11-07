# Script migration: window / terminal / marks / workspaces / scratchpad / wallpaper / theme / compositor

All new scripts are in `config/sway/script/` (deployed as `~/.config/sway/script`).
They keep the subcommands and arguments of the i3 version, so a binding changes from
`$I3_SCRIPT/i3_<x>.sh <args>` to `$SWAY_SCRIPT/sway_<x>.sh <args>`.
I checked them with `bash -n` / `python3 -m py_compile` and ran the jq/awk parts against
mock sway trees. They have **not** been run inside a live sway session.

Shared assets are still read from `~/.config/i3/share` (automark list, workspace name
list, geometry preset files, icons, default wallpaper) and `~/.config/rofi`.

## Script map

| i3 script | sway script | Status |
|---|---|---|
| i3_window_operator.sh | sway_window_operator.sh | ported (one argument degraded) |
| i3_terminal_operator.sh | sway_terminal_operator.sh | ported |
| i3_mark_operator.sh | sway_mark_operator.sh | ported |
| i3_automark_operator.sh | sway_automark_operator.sh | ported |
| i3_automark_daemon.py | sway_automark_daemon.py | **new, required** (the i3 version breaks on sway) |
| i3_automark.py | sway_automark.py | **new, required** (same reason) |
| i3_workspace_operator.sh | sway_workspace_operator.sh | ported; save/restore is partial |
| i3_scratchpad_operator.sh | sway_scratchpad_operator.sh | **new, required** (wmctrl sees XWayland windows only) |
| i3_collect_all_instances.py | sway_collect_all_instances.py | new (matches app_id or X11 instance/class) |
| i3_wallpaper_operator.sh | sway_wallpaper_operator.sh | ported |
| i3_wal_operator.sh | sway_wal_operator.sh | ported |
| i3_picom_operator.sh | sway_opacity_operator.sh | ported to sway opacity; blur needs SwayFX |
| i3_flashfocus_operator.sh | sway_flashfocus_operator.sh | ported |
| i3_apply_template_theme.sh | sway_apply_template_theme.sh | ported |
| i3_new_workspace.sh | (none) | reuse `$I3_SCRIPT/i3_new_workspace.sh` unchanged (it only uses `i3-msg` + jq) |
| i3_swap_master_window.py | (none) | reuse unchanged (python i3ipc works with sway) |

## Per script

### sway_window_operator.sh
- Window identity: `xdotool getwindowfocus` + `[id=<X id>]` is now the focused tree node's
  `.id` + `[con_id=N]`. Floating detection: i3's `"floating":"user_on"` is now node
  `.type == "floating_con"`. Tiled content size: `xdotool getwindowgeometry` is now `.window_rect`.
- Positioning uses `move absolute position X px Y px`. In sway, plain `move position` is
  relative to the workspace. The script computes absolute layout coordinates, as it did on i3.
- rofi is no longer placed with `-w <X window id>`. It opens on the focused output.
- Border width and title styles are read from `set $default_border_width`,
  `set $default_titlebar_style` and `set $default_floating_titlebar_style` in `~/.config/sway/config`.
- The `toggle_sticky_current` titlebar cursor jump calls `$SWAY_SCRIPT/sway_cursor_operator.sh
  move_cursor_inside_window top_titlebar` if that script exists.
- **Full:** center_current, move_floating_to_corner `<corner>`, toggle_sticky_current,
  resize_to_input, move_floating_to_input, resize_to_input_and_move_floating_to_input(_in_one),
  resize_and_move_floating `<1 0 X Y W H>`, show_geometry, float_all, tile_all, hide_all,
  show_all_scratchpad, hide_all_floating, float_then_fulfill_workspace.
- **Partial:** `float_then_fulfill_workspace with_placeholder`. On i3 this ran `i3-msg open`
  to leave an empty placeholder in the tiling layout. sway has no `open` command, so the
  script sends a low-urgency notification and floats/fills the window without a placeholder.

### sway_terminal_operator.sh
- set_default_terminal rewrites the first `set $terminal <cmd>` line of
  `~/.config/sway/config`, then runs `swaymsg reload`. The rofi list offers kitty, foot and
  i3-sensible-terminal, and you can type any other command.
- attach_to_tmux_session `<session|cmd> [floating]` and attach_to_selected_tmux_session
  `[tiling|floating]` launch with `swaymsg exec`. With `floating`, kitty gets
  `--class floating_terminal`, which becomes app_id `floating_terminal` on Wayland.
- close_terminal_and_capture_tmux_cmd takes the title from the focused node's `.name`
  (was xprop), kills it with `[con_id=N] kill`, and copies with `wl-copy` (was xclip).
- **All full.**

### sway_mark_operator.sh
- `i3-input` is replaced by a rofi prompt (`i3_input_compat`, which substitutes `%s`). The `i3`
  and `none` selectors therefore also use rofi.
- Marked windows are listed with jq. sway emits `"marks": []` on every node, so the i3 grep
  pipeline would have matched every container. Entries look like `"<mark>" <title>`.
- title_on/title_off behave as on i3: `[con_mark="^.*"] border normal`, then
  `[all]` and `[floating] border` reset to the config defaults.
- unmark_all_automark_and_remark runs `$SWAY_SCRIPT/sway_automark.py`.
- **All full.**

### sway_automark_operator.sh, sway_automark_daemon.py, sway_automark.py
- The i3 python scripts **do not work on sway**, for two reasons:
  1. They find the socket with `i3 --get-socketpath`, which reads an X11 root property and
     needs the i3 binary.
  2. They only count a node as a window if `node['window']` is set. That is the X11 window
     id, which is null for native Wayland windows, so native windows would never be marked.
- The sway versions get the socket from `$SWAYSOCK`, then `$I3SOCK`, then
  `sway --get-socketpath`. They detect windows by pid, app_id, shell or window, walk the
  tree tolerantly, and ignore unknown sway event types.
- The operator moves the cursor to the window centre with
  `swaymsg seat - cursor set X Y` (was xdotool). It runs the daemon detached (`setsid -f`)
  and finds it with `pgrep -f sway_automark_daemon.py`. `enable` no longer starts a second
  daemon.
- **All full:** enable, disable, reload, cycle_focus_inc/dec, cycle_swap_inc/dec.

### sway_workspace_operator.sh
- **Full:** rename_current, goto, goto_with_input, move_container, move_container_not_focus,
  move_container_with_input, move_container_to_output `<dir>`, move_workspace_and_focus
  `<dir|next>`, swap, swap_with_input, swap_with_index `<n>`, swap_next, swap_prev, kill,
  kill_current.
- `i3-workspace-swap -d WS` is replaced by a native swap made of three renames (current, then
  a temporary name, then the target). Each workspace stays on its output, and focus follows
  the content that was focused. If the target workspace does not exist, the current
  workspace is simply renamed to it.
- The bar is shown while rofi is open with `bar bar_mode hidden_state show|hide` (bar id `bar_mode`).
- **Partial:** save, save_current, save_all, restore, restore_current, restore_all.
  i3-resurrect cannot work on sway, because sway has no `append_layout` and no placeholder
  swallowing.
  - **save** writes `~/.local/share/sway-resurrect/workspace_<name>.json`. For each window
    on the workspace it records: app (app_id, or class for XWayland), title, whether it is
    floating, and its argv from `/proc/<pid>/cmdline`.
  - **restore** relaunches each command with
    `swaymsg 'workspace --no-auto-back-and-forth "<ws>"; exec bash <launcher>'`. The launcher
    is a temporary script that `exec`s the saved argv. sway places a new window on the
    workspace its `exec` came from, matched by pid.
  - **Not restored:** split layout, window sizes and floating geometry.
  - Apps that pass the request to an already running instance (for example a browser)
    open wherever that instance decides.
  - kill/kill_current save quietly before killing, as on i3.

### sway_scratchpad_operator.sh
- `wmctrl -l` (desktop -1) is replaced by the `__i3_scratch` workspace in the sway tree.
  wmctrl only sees XWayland windows on sway.
- Selecting a window runs `[con_id=N] scratchpad show`. Menu entries are `<con_id> <app_id|class> <title>`.
- **All full:** select, select_and_send_focus_if_no_one_to_select.

### sway_collect_all_instances.py
- Usage: `sway_collect_all_instances.py <target>`.
- Matches by substring, like the i3 version. The target is compared with the app_id for
  native windows, and with the X11 instance and class for XWayland windows.
- Collects floating views too. i3ipc's `leaves()` skips sway `floating_con` windows, so the
  script walks all descendants instead.
- Quotes the workspace name in the move command.

### sway_wallpaper_operator.sh
- The first argument is still `feh|variety`. With `feh`, the script runs
  `swaymsg output * bg "<file>" fill` (`SWAY_WALLPAPER_MODE` overrides `fill`).
- swaybg cannot be asked which file it shows. The script therefore records the last file in
  `~/.cache/sway_wallpaper` (override with `SWAY_WALLPAPER_STATE`). This replaces `~/.fehbg`.
- **Full (feh):** show_current, random `<dir>`, select `<dir>`, restore_default, save_current
  (needs `$WALLPAPERF`), set_default.
- **New:** `restore_last` re-applies the recorded wallpaper. `restore_default quiet` skips the
  notification and is used by the wal startup line.
- **Full (variety):** unchanged (show_current, random, select, set_default, save_current,
  previous, next, pause, resume, quit). variety drives swaybg itself on sway.

### sway_wal_operator.sh
- Runs `wal -n -i <current wallpaper> [--nine] <args>`. `-n` stops wal from setting the
  wallpaper with feh. The current wallpaper is read from `~/.cache/sway_wallpaper`, with
  default_wallpaper as fallback.
- Then it runs `swaymsg reload`, so the borders and bar pick up
  `~/.cache/wal/colors-sway-i3`, and `sway_wallpaper_operator.sh feh restore_last`.
- disable_wal_and_apply_template calls `$SWAY_SCRIPT/sway_apply_template_theme.sh`.
- **All full:** enable_9_color_wal, enable_16_color_wal `[wal args...]`, disable_wal,
  disable_wal_and_apply_template.

### sway_opacity_operator.sh (replaces i3_picom_operator.sh)
- picom's per-class `opacity-rule`s are read from the same files,
  `~/.config/picom/picom_{transparency,blur}.conf`. Each rule
  `"NN:class_g = 'X'"` becomes `[app_id="(?i)^X$"]` / `[class="(?i)^X$"] opacity 0.NN`.
  Windows without a rule get `active-opacity` (override with `SWAY_OPACITY_DEFAULT`).
- Each rule is applied to existing windows and also added as a runtime `for_window` rule, so
  new windows get it too.
- `default` uses the mode the `picom.conf` symlink points to, which is the "Set default picom"
  choice made through `i3_default_valuechanger.sh picom ...`. If there is no symlink it uses
  transparency.
- `blur` only blurs on SwayFX (detected from `swaymsg -t get_version` containing "swayfx",
  then `blur enable`). On plain sway it applies the opacity rules and sends a notification.
- `off` replaces `killall picom`: `[all] opacity 1`, plus `blur disable` on SwayFX.
- `after_i3_restart`: a sway reload drops runtime `for_window` rules, so this re-applies the
  current mode (saved in `$XDG_RUNTIME_DIR/sway_opacity_mode`), or the default mode at login.
  Run it with `exec_always`.
- `restart_running` re-applies the current mode.
- sway always renders client-side alpha (kitty `background_opacity`), whichever mode is active.

### sway_flashfocus_operator.sh
- start, stop and restart are unchanged, except:
  - It no longer waits for picom before starting.
  - The stale-instance check compares against the age of the sway process (was the i3 PID
    via xprop).
- **All full.**

### sway_apply_template_theme.sh
- Copies the template files from `~/.config/i3/theme/templates/<t>/` to `~/.cache/wal/`, as before.
- Then writes `~/.cache/wal/colors-sway-i3` from the template's `colors.json`, in the same
  format as the pywal template (`set $bg`, `set $fg`, `set $c0`..`set $c15`).
- Then runs `swaymsg reload` and restores the wallpaper. `xrdb -load ~/.Xresources` runs
  only when xrdb and `$DISPLAY` exist (for XWayland apps).

## Config lines edited by these scripts

| Script | File | Line located by | Written as |
|---|---|---|---|
| sway_terminal_operator.sh set_default_terminal | `~/.config/sway/config` | first line matching `^set $terminal` | `set $terminal <cmd>` |
| sway_wal_operator.sh enable_16_color_wal | `~/.config/sway/config` | first non-empty, non-comment line after the line containing `Startup-Wal` | `exec wal -n <args> -i $HOME/.config/i3/share/default_wallpaper` |
| sway_wal_operator.sh enable_9_color_wal | same | same | `exec wal --nine -n <args> -i $HOME/.config/i3/share/default_wallpaper` |
| sway_wal_operator.sh disable_wal / disable_wal_and_apply_template | same | same | `exec $SWAY_SCRIPT/sway_wallpaper_operator.sh feh restore_default quiet` |

Files the scripts read but do not write: `~/.config/sway/config` (`set $default_border_width`,
`$default_titlebar_style`, `$default_floating_titlebar_style`) and the `picom.conf` symlink.
State files: `~/.cache/sway_wallpaper`, `$XDG_RUNTIME_DIR/sway_opacity_mode`,
`~/.local/share/sway-resurrect/*.json`, `~/.cache/wal/colors-sway-i3`.

## Required sway config changes
1. Startup: change `exec $I3_SCRIPT/i3_automark_daemon.py` to
   `exec $SWAY_SCRIPT/sway_automark_daemon.py`.
2. Point every binding at the sway scripts with the same arguments:
   `i3_window_operator.sh`, `i3_terminal_operator.sh`, `i3_mark_operator.sh`,
   `i3_automark_operator.sh`, `i3_workspace_operator.sh`, `i3_scratchpad_operator.sh`,
   `i3_wallpaper_operator.sh` (including mode lines that call `feh --bg-fill` directly; use
   `sway_wallpaper_operator.sh feh random|select <dir>`), `i3_wal_operator.sh`,
   `i3_picom_operator.sh` → `sway_opacity_operator.sh`, `i3_flashfocus_operator.sh`.
3. In the picom mode, change `[0] killall picom` to `$SWAY_SCRIPT/sway_opacity_operator.sh off`.
4. `swaymsg reload` re-applies `output * bg default_wallpaper`, which resets a wallpaper
   chosen at runtime. Add this after that line (or replace it with it):
   `exec_always $SWAY_SCRIPT/sway_wallpaper_operator.sh feh restore_last`
5. Keep the `# Startup-Wal` marker in `~/.config/sway/config`, followed by exactly one command line.
6. Keep `exec_always $SWAY_SCRIPT/sway_opacity_operator.sh after_i3_restart` (already present).

## Packages
| Purpose | apt (Ubuntu 24.04) | dnf (Fedora) |
|---|---|---|
| core | sway swaybg jq | sway swaybg jq |
| menus | rofi (1.7.5 in 24.04 is X11-only and runs through XWayland) | rofi-wayland (or rofi ≥ 2.0) |
| clipboard | wl-clipboard | wl-clipboard |
| notifications | libnotify-bin | libnotify |
| python IPC (collect, swap_master) | python3-i3ipc | python3-i3ipc |
| tmux attach | tmux | tmux |
| process tools | procps psmisc | procps-ng psmisc |
| wallpaper rotation | variety | variety |
| pywal | pipx install pywal (or pywal16) | pipx install pywal (or pywal16) |
| flashfocus | pipx install flashfocus | pipx install flashfocus |
| blur (optional) | SwayFX (not in Ubuntu repos, build from source) | SwayFX (COPR `swayfx/swayfx`) |
| Xresources for XWayland (optional) | x11-xserver-utils | xrdb |

xdotool, xprop, xclip, wmctrl, feh, picom, i3-input and i3-resurrect are no longer needed.
`i3-msg` (package i3-wm / i3) is only needed if you keep reusing `$I3_SCRIPT/i3_new_workspace.sh`.
