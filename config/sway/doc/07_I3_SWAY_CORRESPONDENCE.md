# 07 — i3 ↔ sway Correspondence (applications and scripts)

This report is a lookup table. For each application or script used under i3 it shows what
sway uses instead, and how the two differ. Details live in the other reports:
- per-script subcommands: [02](02_SCRIPT_PORTING.md) and [`migration/`](migration/)
- why each X11 tool has to change: [03](03_X11_TO_WAYLAND_CHANGES.md)
- packages: [05](05_PACKAGES_AND_INSTALL.md)

Legend:
- **same**: the same program and configuration
- **same\***: the same program, configured differently on sway
- **replaced**: a different program

---

## 1. Applications

### 1.1 Window manager and desktop shell

| Role | i3 (X11) | sway (Wayland) | Relation | Difference / where |
| :-- | :-- | :-- | :-- | :-- |
| Window manager | i3 | sway | replaced | Same config language. i3-only directives converted or dropped: [01](01_CONFIG_CONVERSION.md). `i3-msg` still works (sway exports `I3SOCK`); `swaymsg` is the native client. |
| Session start | GDM "i3" (Xsession sources `~/.profile`) | `sway-session` (`/usr/local/bin`, from `script/sway_session.sh`) | replaced | Both "Sway" login entries start it (stock entry diverted by the installer). It sources `~/.profile` and the input-method env file, sets the Wayland toolkit variables, and adds `--unsupported-gpu` on NVIDIA. |
| Environment for apps | `~/.profile` | `sway-session` + `~/.config/environment.d/60-sway-input-method.conf` + `script/sway_run.sh` | replaced | `sway_run.sh` wraps terminal, rofi and bar launches, so apps get PATH and IM variables even without `sway-session`. |
| Bar | i3bar | swaybar | replaced | Same `bar {}` block. Tray is StatusNotifierItem only. Tray right-click menus need sway ≥ 1.11. |
| Status line | bumblebee-status | bumblebee-status | same\* | Started through `sway_run.sh` (pip `--user` path). Same modules and theme. |
| Dialog bar | i3-nagbar | swaynag | replaced | Exit prompt, battery popup. |
| Compositor effects | picom (opacity, blur, shadows, fading, rounded corners) | sway `opacity` (built in); SwayFX optional | replaced | Opacity only on stock sway (`sway_opacity_operator.sh`). Blur, shadows and corners need SwayFX. No fading. |
| Focus flash | flashfocus (needs picom) | flashfocus | same\* | Talks to sway IPC directly, no picom. |
| Auto tiling | autotiling | autotiling | same | Supports sway natively. Launched through `sway_run.sh`. |
| Window marks | i3-automark (i3ipc, X11 socket lookup) | `sway_automark_daemon.py` / `sway_automark.py` | replaced (port) | The i3 versions find the socket through X11 and skip windows without an X id. |
| Layout save/restore | i3-resurrect | `sway_workspace_operator.sh` save/restore | replaced | Relaunch-only: programs return to their workspace. Splits and geometry are not restored (no `append_layout` in sway). |
| Workspace swap | i3-workspace-swap | three `rename workspace` commands | replaced | In `sway_workspace_operator.sh`. |
| Launcher | rofi 1.7 (X11) | rofi ≥ 2.0 (Wayland, built from source on Ubuntu 24.04) | same\* | Shared `.rasi` files: `Control+c` removed from `kb-cancel` (clashed with 2.0's copy key), `windowcd` removed from `modi`. |
| Window switcher | `rofi -show window/windowcd` | `sway_window_switcher.sh all\|same_app` | replaced | X window lists only contain XWayland windows. |
| Notifications | dunst | dunst ≥ 1.6 | same\* | Layer-shell. `follow = mouse` behaves like `keyboard`. `dmenu = rofi` (no `/usr/bin` path). |
| System monitor overlay | conky (X11 `own_window`) | conky ≥ 1.19 (`out_to_wayland`) | same\* | `sway_conky_monitor_display.sh` runs Wayland-patched copies; your conky files stay unchanged. |
| Wallpaper | feh `--bg-*` | swaybg via `output * bg` | replaced | `sway_wallpaper_operator.sh` (keeps the `feh` subcommand names). Variety is unchanged. ranger's "wallpaper" open-with entries use `swaymsg output * bg`. |
| Colors | Xresources + `set_from_resource` | pywal template `colors-sway-i3` + `include` | replaced | `share/wal_templates/colors-sway-i3`; `xrdb` is still used for XWayland apps. |
| GTK settings | xsettingsd | xsettingsd (XWayland) + `sway_import_gsettings.sh` (native GTK) | same\* | Native GTK apps read gsettings, not XSETTINGS. |
| Polkit / network / bluetooth / phone | polkit-gnome, nm-applet, blueman-applet, kdeconnect-indicator | same | same\* | `nm-applet --indicator`. The polkit path falls back for Fedora. KDE Connect remote input is unavailable. |
| Portals (screen share, file chooser) | none needed | xdg-desktop-portal-wlr + -gtk + PipeWire | new | `share/sway-portals.conf`. Screen sharing in browsers, Zoom and OBS needs it. |

### 1.2 Lock, idle, power

| Role | i3 (X11) | sway (Wayland) | Relation | Difference / where |
| :-- | :-- | :-- | :-- | :-- |
| Screen locker | i3lock | swaylock | replaced | `sway_lock_operator.sh`. Blurred lock through a grim screenshot per output. |
| Idle / auto-lock | xss-lock + `xset dpms` | swayidle | replaced | `sway_idle_operator.sh`: lock after 600 s, outputs off after 610 s, lock before sleep. |
| Caffeine | `xset s off -dpms` | swayidle restarted without timeouts | replaced | `sway_toolkit_operator.sh enable/disable_caffeine`. |
| Fullscreen video keeps the screen on | X screensaver reset by players | `inhibit_idle fullscreen` for every window | new | `sway_window.config`. |
| Lid | (handled outside i3) | `bindswitch lid:on/off` | new | Turns the internal panel off and on. |

### 1.3 Display and input

| Role | i3 (X11) | sway (Wayland) | Relation | Difference / where |
| :-- | :-- | :-- | :-- | :-- |
| Output layout | xrandr, arandr, autorandr | `swaymsg output`, wdisplays, kanshi, wlr-randr | replaced | `sway_display_operator.sh`. No "primary" output: "primary" moves workspace 1 and focus. |
| Mirroring | `xrandr --same-as` | wl-mirror | replaced | A mirror window, not true mirroring. |
| Backlight | xbacklight | brightnessctl | replaced | `sway_backlight_operator.sh`. User must be in the `video` group. |
| Per-monitor brightness | `xrandr --brightness` | ddcutil (external) / `gammastep -b` (all outputs) | replaced | Software dimming per output is not possible. |
| Night light | redshift | gammastep (or wlsunset) | replaced | `sway_nightlight.sh`. |
| Keyboard layout / options / repeat | setxkbmap, xmodmap, `xset r` | `input type:keyboard {…}`, generated `xkb_file` | replaced | `sway_input_output.config`, `sway_keyboard_operator.sh`. |
| NumLock on | numlockx | `xkb_numlock enabled` | replaced | |
| Pointer speed / wheel speed | `xset m`, imwheel | `pointer_accel`, `scroll_factor` | replaced | No per-app or per-button wheel speed. |
| Hide idle cursor | unclutter | `seat * hide_cursor 3000` | replaced | `sway_cursor_operator.sh` edits it. |
| Touchpad gestures | libinput-gestures + xdotool | `bindgesture` | replaced | 18 gestures in `sway_input_output.config`; no `input` group needed. |
| Fake keys / mouse | xdotool | wtype (keys), `seat - cursor` (mouse), ydotool (held modifiers) | replaced | Mouse mode is native. Shift+click-hold needs ydotoold. |
| Keyboard mouse | warpd (X11 build) | warpd (`PLATFORM=wayland` build) | same\* | Rebuilt by the installer. |
| Window info | xprop, xwininfo, wmctrl | `swaymsg -t get_tree` + jq | replaced | Used by every ported script. |
| Input method | ibus + ibus-chewing | **fcitx5 + fcitx5-chewing** (default); ibus selectable | replaced | `$default_input_method`, `sway_input_method.sh`. ibus cannot reach native Wayland apps (no input-method-v2) and its tray needs KDE mode. fcitx5 works natively and its tray shows in swaybar. Ctrl+Alt+space toggles. |
| On-screen keyboard | florence | wvkbd / squeekboard (not installed) | replaced | XTEST typing does not reach Wayland windows. |

### 1.4 Capture, clipboard, media

| Role | i3 (X11) | sway (Wayland) | Relation | Difference / where |
| :-- | :-- | :-- | :-- | :-- |
| Screenshot (PrtScn) | flameshot | grim + slurp + satty/swappy (default); flameshot optional | replaced | `$default_screenshot_tool`, `sway_screenshot_operator.sh`. flameshot's overlay did not appear on sway in testing. |
| Screen recording | peek | wf-recorder | replaced | `sway_recorder.sh`. |
| Show keystrokes | screenkey | showmethekey | replaced | Built from source; reads libinput, needs root through pkexec. |
| Magnifier | magnus, xzoom | woomer | replaced | Built from source (needs GLFW 3.4 and cargo ≥ 1.85; the installer handles both). |
| Color picker | xcolor / gpick | grim + slurp + ImageMagick | replaced | `sway_toolkit_operator.sh`. |
| OCR / QR from screen | flameshot + tesseract / zbar | grim + slurp + tesseract / zbarimg | replaced | |
| Clipboard | xclip, xsel | wl-clipboard (`wl-copy`, `wl-paste`) | replaced | Shared app configs (ranger `yf`, zathura `Ctrl+c`) try `wl-copy` first, then the X11 tool. |
| Clipboard history | parcellite | cliphist | replaced | `sway_toolkit_operator.sh reload_parcellite` (name kept). |
| Terminal image preview | ueberzug | ueberzugpp (`--output wayland`) | replaced | `bin/ueberzug` (sway only). |

### 1.5 Applications that stay the same

kitty, fish, tmux, nvim, ranger, zathura, sioyek, mpv, vis, cava, htop, ncspot,
spotify-tui, pulsemixer, Brave, Firefox and the other apps in
[04](04_XWAYLAND_APP_COVERAGE.md) keep their configuration. They run natively or through
XWayland. kitty is pinned to X11 (`linux_display_server x11`), because ibus only reaches
XWayland windows; on i3 this setting changes nothing.

---

## 2. Scripts

The i3 config calls scripts from `config/i3/script`. On sway each falls into one of these
groups:

| Group | Count | Meaning |
| :-- | --: | :-- |
| Ported | 41 | A sway version `config/sway/script/sway_*` with **the same subcommands and arguments**. The bindings map one to one. |
| Reused | 16 | Called unchanged from `$I3_SCRIPT` (only i3 IPC, which sway provides, or nothing display-related). |
| Not called by the sway config | 9 | No X11 dependency. Called by other scripts, by ranger, or by hand (see 2.3). |
| New (sway only) | 9 + `bin/ueberzug` | Functions i3 got from X11 tools or from `~/.profile`. |

### 2.1 Ported scripts: what is different

| i3 script | sway script | Difference |
| :-- | :-- | :-- |
| `i3_apply_template_theme.sh` | `sway_apply_template_theme.sh` | Also writes `~/.cache/wal/colors-sway-i3`, not only Xresources. |
| `i3_automark.py` | `sway_automark.py` | Socket found through `SWAYSOCK`/`I3SOCK`, not `i3 --get-socketpath`. Native windows (no X id) are counted. |
| `i3_automark_daemon.py` | `sway_automark_daemon.py` | Same as above; started from `sway_startup.config`. |
| `i3_automark_operator.sh` | `sway_automark_operator.sh` | xdotool cursor move → `seat - cursor set`. |
| `i3_autotiling_operator.sh` | `sway_autotiling_operator.sh` | Edits `sway_startup.config`, starts autotiling through `sway_run.sh`. Refuses to run if the startup line is missing (the i3 version rewrote every line). |
| `i3_backlight_operator.sh` | `sway_backlight_operator.sh` | xbacklight → brightnessctl; `xrandr --brightness` → ddcutil / `gammastep -b`. |
| `i3_bar_decorator.sh` | `sway_bar_decorator.sh` | Edits the swaybar colors in `sway_bar.config` by key name. |
| `i3_bar_operator.sh` | `sway_bar_operator.sh` | `bar_reload` → `swaymsg reload`. Uses `sway_conky_valuechanger.sh`. |
| `i3_battery-popup.sh` | `sway_battery-popup.sh` | i3-nagbar → swaynag. |
| `i3_border_operator.sh` | `sway_border_operator.sh` | Edits the sway config files. Refuses if the target line is missing (the i3 version could overwrite the file). |
| `i3_collect_all_instances.py` | `sway_collect_all_instances.py` | Matches `app_id` (native) or `instance`/`class` (XWayland). |
| `i3_conky_monitor_display.sh` | `sway_conky_monitor_display.sh` | Runs `out_to_wayland` copies from `$XDG_RUNTIME_DIR/sway_conky/`. Chooses the output by focusing it briefly instead of xrandr/xinerama. New `bindkey_on/off`, `system_on/off`. |
| `i3_conky_valuechanger.sh` | `sway_conky_valuechanger.sh` | Reads `$default_conky_*` / `$default_i3bar_*` from the **sway** config. Same sed logic on the shared conky files. |
| `i3_cursor_operator.sh` | `sway_cursor_operator.sh` | unclutter → `hide_cursor`; xdotool → `seat - cursor set`; mouse_follows_focus → `mouse_warping`. |
| `i3_default_valuechanger.sh` | `sway_default_valuechanger.sh` | Edits `set $default_*` in the sway config; `swaymsg reload` instead of restart. Restarts conky through the Wayland wrapper. |
| `i3_display_operator.sh` | `sway_display_operator.sh` | xrandr → `swaymsg output`. Presets work on detected outputs. "primary" emulated. Mirror → wl-mirror. Location profiles → kanshi. |
| `i3_dunst_operator.sh` | `sway_dunst_operator.sh` | Reads bar defaults from the sway config; logger started through `swaymsg exec`. |
| `i3_flameshot_operator.sh` | `sway_screenshot_operator.sh` | **Renamed.** grim + slurp + satty/swappy by default, flameshot only when `$default_screenshot_tool flameshot`. Same subcommands (`GUI`, `select_window`, `active_window`, `current_screen`, `full`, `keep`/`hide`). Errors are logged and notified. |
| `i3_flashfocus_operator.sh` | `sway_flashfocus_operator.sh` | No picom wait (`xprop -root`); starts through `sway_run.sh`. |
| `i3_gap_operator.sh` | `sway_gap_operator.sh` | Edits the sway config files; refuses if the target line is missing. |
| `i3_genereate_workspace_name_list.sh` | `sway_genereate_workspace_name_list.sh` | Writes `sway_workspace_name_list.txt` (does not overwrite i3's list). |
| `i3_i3lock_operator.sh` | `sway_lock_operator.sh` | **Renamed.** i3lock → swaylock; blur from grim screenshots; dunst paused while locked. |
| `i3_kdeconnect_operator.sh` | `sway_kdeconnect_operator.sh` | Pointer-invert subcommands are stubs (picom). |
| `i3_kdeconnect_pointer_daemon.py` | `sway_kdeconnect_pointer_daemon.py` | Matches the window by `app_id`. |
| `i3_keyboard_operator.sh` | `sway_keyboard_operator.sh` | setxkbmap/xmodmap → one generated keymap loaded with `input … xkb_file`. xinput → `input … events`. |
| `i3_mark_operator.sh` | `sway_mark_operator.sh` | i3-input → rofi prompt. |
| `i3_pdf_keyword_search.sh` | `sway_pdf_keyword_search.sh` | Entry point now targets `sway_rofi_omnisearch.sh` (wl-clipboard, swaymsg). |
| `i3_pdf_menu.sh` | `sway_pdf_menu.sh` | Sourced by `sway_rofi_omnisearch.sh` instead of the i3 omnisearch. |
| `i3_picom_operator.sh` | `sway_opacity_operator.sh` | **Renamed.** picom opacity rules → sway `opacity` commands. Blur needs SwayFX. |
| `i3_reload_operator.sh` | `sway_reload_operator.sh` | i3bar → swaybar, xss-lock → swayidle; Xresources only affects XWayland apps. |
| `i3_rofi_omnisearch.sh` | `sway_rofi_omnisearch.sh` | wl-copy, cliphist page, windows from the sway tree, keybindings parsed from the sway files. Accepts both `fdfind` and `fd`. |
| `i3_scratchpad_operator.sh` | `sway_scratchpad_operator.sh` | wmctrl → `__i3_scratch` from the sway tree. |
| `i3_system_status.sh` | `sway_system_status.sh` | X checks → swayidle / opacity / `hide_cursor` / `get_inputs` / `get_bar_config`. |
| `i3_terminal_operator.sh` | `sway_terminal_operator.sh` | xdotool/xprop → node pid/title; xclip → wl-copy. |
| `i3_toolkit_operator.sh` | `sway_toolkit_operator.sh` | Picker / OCR / QR through grim+slurp, xkill → slurp, caffeine → swayidle, parcellite → cliphist, `reload_ibus_daemon` → `sway_input_method.sh restart`. `toggle_oneko` is a stub. |
| `i3_wal_operator.sh` | `sway_wal_operator.sh` | `wal -n` + `swaymsg reload`. |
| `i3_wallpaper_operator.sh` | `sway_wallpaper_operator.sh` | feh → `output * bg`; state in `~/.cache/sway_wallpaper`; `restore_last` on every reload. |
| `i3_window_decoractor.sh` | `sway_window_decoractor.sh` | Edits the sway config files; refuses if the target line is missing. |
| `i3_window_operator.sh` | `sway_window_operator.sh` | Geometry from the tree, `move absolute position`. `with_placeholder` has no placeholder (no `open` in sway). |
| `i3_workspace_operator.sh` | `sway_workspace_operator.sh` | i3-workspace-swap → renames; i3-resurrect → relaunch-only save/restore. |
| `i3_xsslock_operator.sh` | `sway_idle_operator.sh` | **Renamed.** xss-lock → swayidle; new `start/stop/restart/status`. |

### 2.2 Reused unchanged (`$I3_SCRIPT/…` in the sway config)

`i3_bluetooth_operator.sh`, `i3_genereate_conky_system_config.py`, `i3_languagechanger.sh`
(only when ibus is the framework), `i3_memory_notifier.sh`, `i3_MPRIS_notification.sh`,
`i3_MPRIS_operator.sh`, `i3_network_operator.sh`, `i3_new_workspace.sh`,
`i3_notify_logger.sh`, `i3_omnisearch_cache.py`, `i3_pdf_search.py`,
`i3_pulseaudio_notification.sh`, `i3_RF_device_operator.sh`, `i3_single_instance.sh`,
`i3_spotifyd_operator.sh`, `i3_swap_master_window.py`.

These need `i3-msg` (package `i3-wm`/`i3`, kept by the installer) or nothing display-specific.

### 2.3 Not called by the sway config

| Script | Status |
| :-- | :-- |
| `i3_battery_notification.sh` | Used under sway by `sway_system_status.sh`, which takes the `sway_` version of a script when one exists and the `i3_` one otherwise. |
| `i3_spt_track_repeat.sh` | Called by `i3_spotifyd_operator.sh`; works under sway through it. |
| `i3_localsend_operator.sh` | Called by ranger's `rifle.conf`; works under sway. |
| `i3_vis_colorchanger.sh` | Used under sway by `sway_reload_operator.sh` (same `sway_`-or-`i3_` lookup). |
| `i3_check_program_version.sh`, `i3_check_sway_diff.sh`, `i3_diff_check_operator.sh` | Maintenance tools run by hand; display-independent. |
| `i3_file_operator.sh`, `i3_time_notifier.sh` | Not bound in either config; display-independent. |

### 2.4 New sway-only scripts

| Script | Replaces / provides |
| :-- | :-- |
| `sway_session.sh` (→ `/usr/local/bin/sway-session`) | The environment Xsession gave i3: `~/.profile`, IM variables, Wayland toolkit variables, NVIDIA flags, log. |
| `sway_run.sh` | PATH and IM variables for everything launched from bindings, whatever started sway. |
| `sway_session_check.sh` | Login-time sanity check (launcher, IM variables, missing tools). |
| `sway_input_method.sh` | ibus ↔ fcitx5 selection, environment file, toggle, `doctor` report. |
| `sway_ibus.sh` | ibus-daemon with a swaybar-visible tray (KDE mode) and XWayland candidate window. |
| `sway_window_switcher.sh` | rofi `window` / `windowcd`. |
| `sway_nightlight.sh` | redshift. |
| `sway_recorder.sh` | peek. |
| `sway_import_gsettings.sh` | XSETTINGS for native GTK apps. |
| `bin/ueberzug` | ueberzug → ueberzugpp inside sway. |
