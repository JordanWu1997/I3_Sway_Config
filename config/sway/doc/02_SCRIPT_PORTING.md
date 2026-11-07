# 02 — Script Porting Index (`config/i3/script` → `config/sway/script`)

The i3 config calls 49 different scripts in `config/i3/script`. Each was put into one of
three groups:

1. **Reused unchanged.** The script uses i3 IPC (`i3-msg`, python `i3ipc`) or nothing
   display-specific. sway exports `I3SOCK` (`sway/ipc-server.c`), so these are called
   from the sway config as `$I3_SCRIPT/i3_*.sh`.
2. **Ported.** The script depends on X11 tools (xdotool, xrandr, xprop, xclip, feh,
   picom, i3lock, …), edits the i3 config files, or detects windows by X11 id or class.
   A sway version `$SWAY_SCRIPT/sway_*.sh` keeps **the same subcommands and arguments**,
   so the bindings map 1:1.
3. **New sway-only helpers.** Functions that i3 got from X11 tools directly.

Every subcommand that cannot work on Wayland is kept as a stub. The stub shows a
notification with the reason and the alternative, so no binding fails silently.

Detailed per-script reports (subcommand-level status, replaced tools, state files, edited
config lines, packages):

| Report | Scripts |
| :-- | :-- |
| [`migration/scripts_display_input.md`](migration/scripts_display_input.md) | display, backlight, keyboard, cursor, conky display, KDE Connect |
| [`migration/scripts_session_tools.md`](migration/scripts_session_tools.md) | lock, idle, toolkit, screenshot, reload, battery popup, system status (+ audit of 15 shared scripts) |
| [`migration/scripts_window_workspace_theme.md`](migration/scripts_window_workspace_theme.md) | window, terminal, marks, automark, workspace, scratchpad, wallpaper, pywal, opacity (picom), flashfocus, template theme |
| [`migration/scripts_bar_defaults_menus.md`](migration/scripts_bar_defaults_menus.md) | bar, bar decorator, default value changer, gap, border, window decorator, omnisearch, pdf menu, dunst, autotiling, workspace name list |

## 1. Ported scripts (41 files)

| i3 script | sway script | Status | Main replacements / limits |
| :-- | :-- | :-- | :-- |
| `i3_display_operator.sh` | `sway_display_operator.sh` | ⚠️ mostly full | xrandr → `swaymsg output`. Presets → detected outputs. Modes the panel lacks → native mode + fractional scale. `*_primary` emulated (moves ws 1 + focus). Mirror → wl-mirror. `auto_in_office/at_home` → `kanshictl switch` (needs kanshi). |
| `i3_backlight_operator.sh` | `sway_backlight_operator.sh` | ✅ / ⚠️ | xbacklight → brightnessctl. Per-display `xrandr --brightness` → ddcutil (external) or `gammastep -b` (all outputs at once). |
| `i3_keyboard_operator.sh` | `sway_keyboard_operator.sh` | ✅ / ⚠️ | setxkbmap/xmodmap → one generated keymap via `input type:keyboard xkb_file`. xset r → repeat_rate/delay. xinput → `input … events`. Caps/NumLock sends via wtype may not toggle the lock state. **Note:** once `default` runs, the keymap file overrides `xkb_layout`/`xkb_options` in `sway_input_output.config`. |
| `i3_cursor_operator.sh` | `sway_cursor_operator.sh` | ✅ | `move_cursor_inside_window` → tree + `seat - cursor set`. unclutter → `hide_cursor`. mouse_follows_focus → `mouse_warping container`. |
| `i3_conky_monitor_display.sh` | `sway_conky_monitor_display.sh` | ⚠️ | Runs Wayland-patched copies (`out_to_wayland`) in `$XDG_RUNTIME_DIR/sway_conky/`, never edits your conky files. Picks an output by focusing it briefly. New `bindkey_on/off`, `system_on/off` (used by the conky modes). |
| `i3_kdeconnect_operator.sh` / `_pointer_daemon.py` | `sway_kdeconnect_operator.sh` / `.py` | ⚠️ | Pointer daemon matches the app_id. `pointer_invert_*` stubbed (picom). Phone remote input is not possible on wlroots. |
| `i3_i3lock_operator.sh` | `sway_lock_operator.sh` | ✅ | i3lock → swaylock. Blurred-desktop lock via grim per output (or swaylock-effects). dunst paused while locked. |
| `i3_xsslock_operator.sh` | `sway_idle_operator.sh` | ✅ | xss-lock → swayidle (lock 600 s, outputs off 610 s, before-sleep, `loginctl lock-session`). Idempotent for `exec_always`. New `start/stop/restart/status`. |
| `i3_toolkit_operator.sh` | `sway_toolkit_operator.sh` | ✅ (1 stub) | Color pick (grim + slurp + ImageMagick), OCR, QR, xkill → slurp window pick, caffeine → swayidle without timeouts (state `$XDG_RUNTIME_DIR/sway_caffeine`), parcellite → cliphist watchers, wl-copy/wl-paste. `toggle_oneko` stubbed (unbound). |
| `i3_flameshot_operator.sh` | `sway_screenshot_operator.sh` | ✅ | grim + slurp (dimmed selection) + satty/swappy editor. Saves to `~/Pictures` and copies to the clipboard. `hide` mode removes borders temporarily. PrtScn tool chosen by `$default_screenshot_tool grim\|flameshot` (default grim; flameshot never showed its overlay on sway in test_v3). Errors → notification + `$XDG_RUNTIME_DIR/sway_screenshot.log`. `start_daemon` starts the flameshot tray only when selected. |
| `i3_reload_operator.sh` | `sway_reload_operator.sh` | ✅ / ⚠️ | i3bar → swaybar, xsslock → swayidle. `Xresources` affects XWayland apps only. |
| `i3_battery-popup.sh` | `sway_battery-popup.sh` | ✅ | i3-nagbar → swaynag. |
| `i3_system_status.sh` | `sway_system_status.sh` | ✅ | X checks → swayidle/opacity/`hide_cursor`/`get_inputs`/`get_bar_config`. New keyboard-layout row. |
| `i3_window_operator.sh` | `sway_window_operator.sh` | ✅ (1 partial) | xdotool geometry → tree rects, `move absolute position`. `float_then_fulfill_workspace with_placeholder` has no placeholder (no `open`). |
| `i3_terminal_operator.sh` | `sway_terminal_operator.sh` | ✅ | xdotool/xprop → node pid/title. xclip → wl-copy. Edits `set $terminal`. |
| `i3_mark_operator.sh` | `sway_mark_operator.sh` | ✅ | i3-input → rofi prompt. |
| `i3_automark_operator.sh` | `sway_automark_operator.sh` | ✅ | xdotool cursor move → `seat - cursor set`. |
| `i3_automark_daemon.py`, `i3_automark.py` | `sway_automark_daemon.py`, `sway_automark.py` | ✅ (required) | The i3 versions find their socket via `i3 --get-socketpath` (X11) and only count nodes with an X window id, so native windows would never get marks. |
| `i3_workspace_operator.sh` | `sway_workspace_operator.sh` | ✅ / ⚠️ | i3-workspace-swap → three renames. **i3-resurrect → relaunch-only save/restore** (`~/.local/share/sway-resurrect/`): commands come back on their workspace, but split layout and geometry do not (sway has no `append_layout`). |
| `i3_scratchpad_operator.sh` | `sway_scratchpad_operator.sh` | ✅ (required) | wmctrl only sees XWayland windows → reads `__i3_scratch` from the tree. |
| `i3_collect_all_instances.py` | `sway_collect_all_instances.py` | ✅ | app_id (native) or instance/class (XWayland). |
| `i3_wallpaper_operator.sh` | `sway_wallpaper_operator.sh` | ✅ | feh → `output * bg`. State in `~/.cache/sway_wallpaper` (swaybg cannot be queried). New `restore_last`, run on every reload. Variety unchanged. |
| `i3_wal_operator.sh` | `sway_wal_operator.sh` | ✅ | `wal -n` + `swaymsg reload`. Rewrites the line after `Startup-Wal` in `config`. |
| `i3_picom_operator.sh` | `sway_opacity_operator.sh` | ⚠️ | picom opacity-rules → sway `opacity` + runtime for_window. `default` follows the `~/.config/picom/picom.conf` link, as i3's "set default picom" did. Blur only with SwayFX. `off` = opaque. |
| `i3_flashfocus_operator.sh` | `sway_flashfocus_operator.sh` | ✅ | No picom wait (the i3 version used `xprop -root I3_PID`). |
| `i3_apply_template_theme.sh` | `sway_apply_template_theme.sh` | ✅ | Writes `~/.cache/wal/colors-sway-i3` instead of Xresources-only. |
| `i3_bar_operator.sh` | `sway_bar_operator.sh` | ✅ | `bar_reload` → `swaymsg reload` (also resets runtime gap changes). |
| `i3_bar_decorator.sh` | `sway_bar_decorator.sh` | ✅ | Edits colors by key name. |
| `i3_default_valuechanger.sh` | `sway_default_valuechanger.sh` | ✅ | Edits `set $default_*` in the sway config and the sway startup lines; `swaymsg reload` instead of restart. `conky_style` relaunches conky through `sway_conky_monitor_display.sh` (Wayland copy), not raw `conky -c`. |
| `i3_conky_valuechanger.sh` | `sway_conky_valuechanger.sh` | ✅ | Same CLI and sed logic. Reads `$default_conky_*` / `$default_i3bar_*` from the **sway** config instead of `~/.config/i3/config` (78 bindings use it). The conky files themselves stay shared with i3. |
| `i3_gap_operator.sh`, `i3_border_operator.sh`, `i3_window_decoractor.sh` | `sway_*` | ✅ | Edit the sway config files; refuse to run if the target line is missing (the i3 versions could overwrite whole files). |
| `i3_rofi_omnisearch.sh` (+ `pdf_menu`, `pdf_keyword_search`) | `sway_rofi_omnisearch.sh` (+ `sway_pdf_menu.sh`, `sway_pdf_keyword_search.sh`) | ✅ | wl-copy. Windows page from the sway tree. Keybindings page parses the sway files. Clipboard page uses cliphist. fd is resolved as `fdfind` (Ubuntu) or `fd` (Fedora); the i3 version only works with `fdfind`. |
| `i3_dunst_operator.sh`, `i3_autotiling_operator.sh` | `sway_*` | ✅ | Read/edit the sway config files. |
| `i3_genereate_workspace_name_list.sh` | `sway_genereate_workspace_name_list.sh` | ✅ | Writes `~/.config/i3/share/sway_workspace_name_list.txt` (does not clobber i3's list). |

## 2. Reused unchanged from `$I3_SCRIPT`

These scripts were checked and have no X11 or i3-config dependency:

- `i3_new_workspace.sh` (i3-msg + jq)
- `i3_swap_master_window.py` (i3ipc)
- `i3_pulseaudio_notification.sh`
- `i3_MPRIS_notification.sh`, `i3_MPRIS_operator.sh`
- `i3_spotifyd_operator.sh`, `i3_spt_track_repeat.sh`
- `i3_bluetooth_operator.sh`, `i3_network_operator.sh`, `i3_RF_device_operator.sh`
- `i3_memory_notifier.sh`, `i3_notify_logger.sh`, `i3_time_notifier.sh`
- `i3_battery_notification.sh`, `i3_localsend_operator.sh`, `i3_single_instance.sh`
- `i3_languagechanger.sh` (ibus CLI; called by `sway_input_method.sh toggle` when ibus is the running framework)
- `i3_genereate_conky_system_config.py`, `i3_omnisearch_cache.py`, `i3_pdf_search.py`
- `i3_vis_colorchanger.sh`, `i3_diff_check_operator.sh`

`i3_file_operator.sh` is shared too, but it execs the i3 omnisearch from its own
directory. Call `sway_rofi_omnisearch.sh` directly from sway bindings.

**Requirement:** `i3-msg` comes from the `i3-wm` package. Keep it installed (the install
script does), or switch these scripts to `swaymsg` later.

## 3. New sway-only helpers (written for this migration)

| Script | Purpose |
| :-- | :-- |
| `sway_session.sh` | Session launcher (`/usr/local/bin/sway-session`): sources `~/.profile`, exports the Wayland toolkit variables, adds `--unsupported-gpu` for NVIDIA, logs to `~/.local/state/sway.log`. |
| `sway_window_switcher.sh` | `rofi -show window/windowcd` replacement built from the sway tree (`all`, `same_app`). |
| `sway_nightlight.sh` | redshift replacement (`set <K>`, `off`, `status`) with gammastep/wlsunset. |
| `sway_recorder.sh` | peek replacement (`toggle region|output`, `stop`) with wf-recorder. |
| `sway_import_gsettings.sh` | Copies GTK 3 `settings.ini` into gsettings so native GTK apps use your theme. |
| `sway_run.sh` | Runs a command with the environment i3 had: PATH (`~/.local/bin`, `$I3_SCRIPT`, `$SWAY_SCRIPT`, cargo/go bins, `~/.config/sway/bin`) and the input-method variables from the environment.d file. bumblebee-status, autotiling, flashfocus, all rofi bindings and all 23 terminal bindings go through it, so everything they start gets the variables even when sway itself lacks them. |
| `sway_session_check.sh` | At login: reports when sway was not started by `sway-session`, the IM variables are missing, the environment.d file is missing (creates it), fcitx5-chewing / the fcitx5 ibus front end are missing, or bumblebee-status/autotiling/ibus are not installed. Log: `$XDG_RUNTIME_DIR/sway_session_check.log`. |
| `sway_input_method.sh` | `start`, `restart`, `toggle`, `status`, `doctor` (writes `~/sway_im_doctor.txt`), `use ibus\|fcitx5`, `write_env`. Starts the framework set by `$default_input_method` (default **fcitx5**) and stops the other one. Keeps `~/.config/environment.d/60-sway-input-method.conf` (IM variables + PATH) in step with it; `sway-session` and `sway_run.sh` read that file (GDM did **not** import it in testing). Ensures the fcitx5 profile contains keyboard-us + chewing. `toggle` (Ctrl+Alt+space) follows the running daemon: `fcitx5-remote -t` or `i3_languagechanger.sh`. |
| `sway_ibus.sh` | `start`/`restart` ibus-daemon with `XDG_CURRENT_DESKTOP=KDE` (StatusNotifier tray icon for swaybar) and `GDK_BACKEND=x11` (candidate window as an XWayland popup). |
| `../bin/ueberzug` | Inside sway only: redirects ranger's `ueberzug layer` to `ueberzugpp layer --output wayland`. Elsewhere it passes through to the normal ueberzug. |

## 4. Verification done

- `bash -n` on every `*.sh` and `python3 -m py_compile` on every `*.py` in
  `config/sway/script`: all pass.
- Agents ran the file-editing and parsing parts against copies of the config and mock
  `swaymsg` trees:
  - default value changer, bar and window decorators, gap/border/autotiling operators
  - workspace list, system status
  - display, backlight, keyboard, cursor and conky helpers
  - jq window filters
- The generated keymap of `sway_keyboard_operator.sh` was compiled with `xkbcomp`.
- The static config checker confirms that every `$SWAY_SCRIPT/...` path referenced by
  the config exists.
- **Not done:** running any script inside a live sway session. sway is not installed on
  this machine (Pop!_OS 22.04).
