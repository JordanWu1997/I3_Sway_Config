# Script migration: lock / idle / caffeine / screenshot / toolkit / reload / status / battery

All new scripts live in `config/sway/script/` (deployed as `~/.config/sway/script/`). They keep the
subcommands and arguments of the i3 originals, so sway bindings are `$SWAY_SCRIPT/<new> <same args>`.
Shared assets (icons, wallpapers) are still read from `~/.config/i3/share`.

| i3 script | sway script |
|---|---|
| `i3_i3lock_operator.sh` | `sway_lock_operator.sh` |
| `i3_xsslock_operator.sh` | `sway_idle_operator.sh` |
| `i3_toolkit_operator.sh` | `sway_toolkit_operator.sh` |
| `i3_flameshot_operator.sh` | `sway_screenshot_operator.sh` |
| `i3_reload_operator.sh` | `sway_reload_operator.sh` |
| `i3_battery-popup.sh` | `sway_battery-popup.sh` |
| `i3_system_status.sh` | `sway_system_status.sh` |

## sway_lock_operator.sh (i3lock → swaylock)

| Subcommand | State | Notes |
|---|---|---|
| `default` | full | `swaylock -f -F -s fill -i default_thinkpad_wallpaper.png` |
| `current_default_wallpaper` | full | same PNG conversion as before (`magick mogrify` or `mogrify`) |
| `current_wallpaper` | full | wallpaper read from the `swaybg -i PATH` command line, `~/.fehbg` fallback |
| `current_desktop` | full | `grim -o OUTPUT` for each output, blurred `0x12`, `swaylock -i OUTPUT:img`; swaylock-effects (if installed) uses `--screenshots --effect-blur` instead |
| `mannual_suspend` | full | blurred lock, then `systemctl suspend` |

- `i3lock -n` (no fork) became `swaylock -f` (daemonize after the lock is shown). This way swayidle's
  `before-sleep`/`lock` handlers return as soon as the screen is locked. dunst is paused like before;
  a background waiter (`tail --pid`) un-pauses it and removes the screenshots after unlock.
- If swaylock is already running, the script exits. This matters because the `lock` and
  `before-sleep` events can both fire.
- Screenshots are kept in `${XDG_RUNTIME_DIR}/sway_lock/` (tmpfs, per user), not in `/tmp`.

## sway_idle_operator.sh (xss-lock → swayidle)

| Subcommand | State |
|---|---|
| `current_desktop`, `current_wallpaper`, `current_default_wallpaper`, `default` | full: they set the lock style and (re)start swayidle |
| `start` / `restart` (new) | restart with the last lock style (default `current_desktop`) |
| `stop` (new) | stop swayidle |
| `status` (new) | print the state; exit status 1 when stopped |

swayidle command (when caffeine is off):

```
swayidle -w timeout 600 '<lock>' timeout 610 'swaymsg "output * power off"' \
         resume 'swaymsg "output * power on"' before-sleep '<lock>' lock '<lock>' \
         unlock 'pkill -USR1 -x swaylock'
```

`<lock>` is `$SWAY_SCRIPT/sway_lock_operator.sh <style>`. Timeouts can be overridden with
`SWAY_IDLE_LOCK_TIMEOUT` / `SWAY_IDLE_DPMS_TIMEOUT`. The old xset values were 600/600; the screen now
turns off 10 s after the lock so the lock screenshot is taken first.

- **Idempotent:** every start kills only the swayidle it launched itself (the cmdline contains
  `sway_lock_operator.sh`). It does not touch the one-shot swayidle in the Super+Shift+L binding.
  Concurrent calls are serialized with `flock` on `${XDG_RUNTIME_DIR}/sway_idle_operator.lock`.
  `exec_always` on every `swaymsg reload` is therefore safe.
- `loginctl lock-session` keeps working through the `lock` event.
- State files: `${XDG_RUNTIME_DIR}/sway_idle_mode` (lock style) and `${XDG_RUNTIME_DIR}/sway_caffeine`.

## Caffeine (xset s off / -dpms → swayidle without timeouts)

- `sway_toolkit_operator.sh enable_caffeine` writes `on` to `${XDG_RUNTIME_DIR}/sway_caffeine` and runs
  `sway_idle_operator.sh start`. swayidle then restarts with only `before-sleep`/`lock`/`unlock`, so
  the screen never blanks or auto-locks, but suspend and `loginctl lock-session` still lock (as
  xss-lock did under xset caffeine).
- `disable_caffeine` writes `off` and restarts swayidle with the timeouts.
- The state lives in tmpfs, so it resets at every boot. The startup line
  `config/sway/config.d/sway_startup.config:64`
  `exec $SWAY_SCRIPT/sway_toolkit_operator.sh enable_caffeine` (or `disable_caffeine`) sets it at
  each login. That is the line the caffeine_startup option of `sway_default_valuechanger.sh` must rewrite
  (same sed pattern as i3, with `sway_toolkit_operator\.sh` and `exec ` without `--no-startup-id`).
  A `swaymsg reload` keeps the current caffeine state, because the idle operator reads the file.
- Alternative not used: sway `inhibit_idle` applies to each window, not globally.

## sway_toolkit_operator.sh

| Subcommand | State | Replacement |
|---|---|---|
| `kill_window` | full | visible window rects → `slurp -r` → geometry mapped back to con_id → `swaymsg [con_id=N] kill` |
| `pickup_color` | full | `grim -g "$(slurp -p)" -t ppm - \| magick/convert - -format '%[hex:p{0,0}]' info:` → `#rrggbb` → wl-copy |
| `get_screenshot_text` | full | `grim -g "$(slurp)"` → `tesseract -l eng+chi_tra` → wl-copy |
| `get_screenshot_qr` | full | `grim+slurp` → white border → `zbarimg` → wl-copy |
| `collect_all_instances` | full | rofi list from `swaymsg -t get_tree` (`con_id  app_id-or-X11-instance  title`); 2nd field goes to `$SWAY_SCRIPT/sway_collect_all_instances.py` |
| `enable_caffeine` / `disable_screensaver` | full | see Caffeine |
| `disable_caffeine` / `enable_screensaver` | full | see Caffeine |
| `toggle_oneko` | **stub** | oneko only follows the X11 pointer (it was not bound in the i3 config either) |
| `reload_parcellite` | full (cliphist) | kills `wl-paste … --watch cliphist` watchers and starts `wl-paste --type text --watch cliphist store` and `wl-paste --type image --watch cliphist store`. If cliphist is missing, it notifies and exits 1 |
| `reload_ibus_daemon` | full | `swaymsg exec 'ibus-daemon -r -d -x'` |
| `reload_gestures` | partial | runs `libinput-gestures-setup restart` if installed, otherwise reports that sway's native `bindgesture` replaces it |
| `show_brave_browser` | full | windows whose title ends in ` - Brave` → rofi → `swaymsg [con_id=N] focus` → `sway_cursor_operator.sh move_cursor_inside_window` |
| `kill_process` | full | unchanged |
| `test_audio_IO` | full | unchanged (arecord/aplay) |
| `translate_clip` | full | `wl-paste` / `wl-copy` |

Clipboard history picker (for the config, not part of this script):
`cliphist list | rofi -dmenu | cliphist decode | wl-copy`.
Screen recording (peek) is handled by the coordinator's `sway_recorder.sh`, not by this toolkit.

## sway_screenshot_operator.sh (flameshot → grim/slurp/swappy)

Usage stays `GUI|select_window|active_window|current_screen|full [keep|hide]`, and all modes are full.

- Captures are saved to `~/Pictures/Screenshot_<YYYY-mm-dd_HH-MM-SS>.png` and copied to the clipboard
  (`wl-copy --type image/png`).
- `GUI`: you select a region with slurp, then it opens in swappy if installed (like flameshot's
  editor). `select_window` uses `slurp -r` over visible window rects. `active_window` uses the
  focused `.rect` (window plus border, no titlebar). `current_screen` uses `grim -o <focused output>`.
  `full` uses `grim` on all outputs and saves without opening swappy.
- The interactive modes open swappy afterwards (`swappy -f F -o F`), matching flameshot's
  `gui --region`. Set `SCREENSHOT_EDIT=0` to skip it.
- `hide`: runs `[all] border pixel 0` (the i3 version used `[con_mark="^.*"]`, which depends on automark).
  It restores borders from `$default_border_width`, `$default_titlebar_style` and
  `$default_floating_titlebar_style` in `~/.config/sway/config`, using `[tiling]` and `[floating]`.
  Sway has no `tiling_from` criterion.
- flashfocus is paused and then restarted with `sway_flashfocus_operator.sh start` if that script
  exists, otherwise with plain `flashfocus`.
- flameshot is used only as a fallback when grim or slurp are missing.

## sway_reload_operator.sh

| Subcommand | State | Notes |
|---|---|---|
| `all` | full | dunst, conky, bar, zathura, vis (same order as i3) |
| `conky` | full | `$SWAY_SCRIPT/sway_conky_monitor_display.sh default` |
| `i3bar` (also `swaybar`, `bar`) | full | `sway_bar_operator.sh bar_reload`, falling back to `swaymsg reload` |
| `dunst` | full | `sway_dunst_operator.sh reload_all` if it exists, else `i3_dunst_operator.sh` (toolkit independent) |
| `zathura` | full | `zathura-pywal -a 0.7` |
| `vis` | full | `sway_vis_colorchanger.sh` or `i3_vis_colorchanger.sh` |
| `xsslock` (also `swayidle`) | full | `sway_idle_operator.sh restart` |
| `Xresources` | partial | `xrdb ~/.Xresources` affects XWayland apps only; fails with a notification when `DISPLAY` is unset |

## sway_battery-popup.sh

All options are kept (`-N -L 30` …). `i3-nagbar` became `swaymsg exec "swaynag -t warning -f
'DroidSansMono Nerd Font Bold 12' -m …"`; the font no longer has the `pango:` prefix. The wish popup
is unchanged (XWayland). It still sources `$I3_SCRIPT/i3_single_instance.sh`, which matches on the
script's own basename, so i3 and sway copies do not kill each other.

## sway_system_status.sh

Same subcommands (`show|all|status|session|health|login|tab`), the same rofi three-tab view and the
same "Needs attention" rules.

- Caffeine is read from `${XDG_RUNTIME_DIR}/sway_caffeine`.
- Auto-lock means the swayidle started by `sway_idle_operator.sh` is running.
- The compositor row says `built-in` (`built-in (opacity rules)` when `opacity` appears in the sway
  config). The picom process row was removed.
- Cursor auto-hide comes from the last `seat … hide_cursor <ms>` in the config. Changes made at
  runtime with the Ctrl+button8/9 bindings cannot be seen, because the IPC does not report them.
- Caps Lock comes from `${XDG_RUNTIME_DIR}/sway_keyboard_state` (CAPS=, written by
  `sway_keyboard_operator.sh`), else from `xkb_options` in the config.
- New row: `Keyboard layout` from `swaymsg -t get_inputs` (`xkb_active_layout_name`).
- The bar mode comes from `swaymsg -t get_bar_config bar_status`.
- The config is read from `~/.config/sway/config.d/sway_window.config` and `sway_bindkey.config`.
- Background components:
  - Screen lock helper is swayidle.
  - Clipboard manager means the cliphist watchers. There is one text and one image watcher; these are
    not counted as duplicates.
  - The compositor process row was removed.
  - Window automark, battery warning and notification log rows prefer the `sway_*` scripts and fall
    back to the `i3_*` ones.
- Process ownership across logins compares `WAYLAND_DISPLAY` first, then `DISPLAY`.

## Audit (no port needed, they work under sway as-is)

| Script | Verdict |
|---|---|
| `i3_battery_notification.sh` | OK (sysfs + notify-send) |
| `i3_memory_notifier.sh` | OK (sources `i3_single_instance.sh` from its own dir) |
| `i3_time_notifier.sh` | OK (notify-send only; its notify-send version check is odd but toolkit independent) |
| `i3_notify_logger.sh` | OK (dbus-monitor) |
| `i3_localsend_operator.sh` | OK |
| `i3_file_operator.sh` | Toolkit independent. It execs `i3_rofi_omnisearch.sh` from its own dir; a `sway_rofi_omnisearch.sh` port already exists, so sway bindings should call that script directly |
| `i3_pulseaudio_notification.sh` | OK (pactl) |
| `i3_MPRIS_notification.sh` / `i3_MPRIS_operator.sh` | OK (playerctl; uses `$I3_SCRIPT`, which sway_session.sh/.profile exports) |
| `i3_spotifyd_operator.sh` / `i3_spt_track_repeat.sh` | OK (needs `$I3_SCRIPT` exported and the script dir on PATH, same as under i3) |
| `i3_bluetooth_operator.sh` | OK. `show_error` uses `rofi -e` only when `DISPLAY` is set, otherwise notify-send, so it degrades gracefully without XWayland |
| `i3_network_operator.sh`, `i3_RF_device_operator.sh` | OK (nmcli / rfkill) |
| `i3_single_instance.sh` | OK, generic; reused by `sway_battery-popup.sh` |

Not in this group but noticed: `i3_flashfocus_operator.sh` uses `xprop -root I3_PID` (X only), and
`i3_dunst_operator.sh` starts the notify logger with `i3-msg exec` (works through I3SOCK).

## Packages

| Purpose | Ubuntu 24.04 (apt) | Fedora (dnf) |
|---|---|---|
| lock / idle | `swaylock swayidle` (swaylock-effects: build from source) | `swaylock swayidle` (swaylock-effects: COPR) |
| wallpaper (read by the lock script) | `swaybg` | `swaybg` |
| screenshots | `grim slurp swappy` | `grim slurp swappy` |
| clipboard | `wl-clipboard cliphist` | `wl-clipboard cliphist` |
| image / json | `imagemagick jq file` | `ImageMagick jq file` |
| OCR / QR | `tesseract-ocr tesseract-ocr-eng tesseract-ocr-chi-tra zbar-tools` | `tesseract tesseract-langpack-eng tesseract-langpack-chi_tra zbar` |
| translate | `translate-shell` | `translate-shell` |
| notifications / menus | `libnotify-bin dunst rofi` (noble's rofi runs under XWayland) | `libnotify dunst rofi-wayland` |
| audio test / volume | `alsa-utils pulseaudio-utils` | `alsa-utils pulseaudio-utils` |
| misc (setsid, flock, pgrep, column) | `util-linux procps bsdextrautils` | `util-linux procps-ng` |
| Xresources / Tk popup (optional) | `x11-xserver-utils xwayland tk` | `xrdb xorg-x11-server-Xwayland tk` |
| optional fallbacks | `flameshot`, `libinput-tools` + libinput-gestures (manual) | same |

## Changes the sway config needs

- `sway_startup.config:139`: `exec_always $SWAY_SCRIPT/sway_idle_operator.sh current_desktop` is
  correct as written.
- `sway_startup.config:64`: the caffeine line is correct as written; it must stay a plain
  `exec $SWAY_SCRIPT/sway_toolkit_operator.sh enable_caffeine|disable_caffeine` so the value changer can rewrite it.
- `sway_startup.config:81`: `exec_always … reload_parcellite` is correct (starts the cliphist watchers idempotently).
- Remove any `libinput-gestures-setup start` and use `bindgesture` instead (optional).
- Optional: bind the clipboard history picker:
  `bindsym <key> exec cliphist list | rofi -dmenu | cliphist decode | wl-copy`.
- Optional: `for_window [title="Battery Warning"] sticky enable` (only for the wish popup; `-N` uses swaynag).
- The system mode's Super+Shift+L one-shot swayidle (`sway_mode.config:293`) does not interfere:
  the idle operator only kills the swayidle it started.
