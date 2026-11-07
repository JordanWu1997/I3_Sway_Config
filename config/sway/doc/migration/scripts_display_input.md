# Script migration: display / input / backlight / cursor / keyboard / conky / kdeconnect

All new scripts live in `config/sway/script/` (deployed as `~/.config/sway/script`, `$SWAY_SCRIPT`).
They keep the **same subcommands and arguments** as the i3 versions, so the sway config only swaps
`$I3_SCRIPT/i3_<x>.sh` for `$SWAY_SCRIPT/sway_<x>.sh`. Shared assets (icons, wallpaper) are still read
from `~/.config/i3/share`. Verified only with `bash -n`, `python3 -m py_compile`, and runs against a mocked `swaymsg`.
None of it has been run on a real sway session.

| i3 script | sway script |
| --- | --- |
| `i3_display_operator.sh` | `sway_display_operator.sh` |
| `i3_backlight_operator.sh` | `sway_backlight_operator.sh` |
| `i3_keyboard_operator.sh` | `sway_keyboard_operator.sh` |
| `i3_cursor_operator.sh` | `sway_cursor_operator.sh` |
| `i3_conky_monitor_display.sh` | `sway_conky_monitor_display.sh` |
| `i3_kdeconnect_operator.sh` | `sway_kdeconnect_operator.sh` |
| `i3_kdeconnect_pointer_daemon.py` | `sway_kdeconnect_pointer_daemon.py` |

Runtime state files (all in `${XDG_RUNTIME_DIR:-/tmp}`, so they reset when you log in again):

| file | written by | read by |
| --- | --- | --- |
| `sway_primary_output` | display operator (`*_primary`, `auto`, joint modes) | conky helper, display operator |
| `sway_keyboard_state`, `sway_keyboard.xkb` | keyboard operator | keyboard operator |
| `sway_conky/conky_config_{bindkey,system}` | conky helper (Wayland-patched copies) | conky |

---

## 1. `sway_display_operator.sh <op> [enable|disable]`

**Mapping output names:** the script reads `swaymsg -t get_outputs` once. `eDP1` becomes the first output
matching `^eDP` (or `^(LVDS|DSI)`). `HDMI1` becomes `HDMI-A-1`, or failing that the first `^HDMI` output.
"Has an internal panel" also checks `/sys/class/drm/card*-eDP-*`, so the hotplug retry still works when
eDP has briefly dropped out of the IPC list. The desktop profile uses `SWAY_DESKTOP_OUT_A/B/C`
(defaults `DP-1`, `DP-2`, `HDMI-A-1`; this replaces the NVIDIA X names `DP-1`, `DP-2`, `HDMI-0`).

| subcommand | status | notes |
| --- | --- | --- |
| `auto` | full | Same decision tree. Monitors are told apart by physical size (mm), which needs **wlr-randr** (`wlr-randr --json`). Without it, every HDMI monitor falls into the "Other HDMI" branch (HDMI on the right of eDP, HDMI is primary). |
| `auto_in_office`, `auto_at_home` | partial | `setup_monitors.sh` is xrandr-only. These run `kanshictl switch office` / `home` (rename with `SWAY_KANSHI_OFFICE_PROFILE` / `SWAY_KANSHI_HOME_PROFILE`). If kanshi is missing they show a notification and exit 1. |
| `eDP1_HDMI1_joint`, `HDMI1_eDP1_joint` | full | Both outputs in their preferred mode, side by side; HDMI becomes primary. |
| `eDP1_HDMI1_mirror` | partial | No built-in mirroring. Both outputs are enabled, then `wl-mirror --fullscreen-output HDMI eDP` runs. Any non-mirror layout command kills `wl-mirror`. |
| `eDP1_auto`, `HDMI1_auto` | full | `output X enable mode <preferred>`. The preferred mode comes from wlr-randr, or else the largest mode. |
| `eDP1_off`, `HDMI1_off` | full | `output X disable` |
| `eDP1_default`, `HDMI1_default` | full | `mode 1920x1080 scale 1` |
| `eDP1_1440x810_60`, `eDP1_1368x768_60` | full (emulated) | eDP panels rarely accept custom modes. If the mode is not in the panel's list, the panel stays at its native mode and the script sets `scale native_w/target_w` (1920/1440 = 1.3333). The logical size is the same as the old shrink mode. |
| `HDMI1_1920x1200_50`, `HDMI1_1912x960_60` | full | `mode --custom WxH@RHz` (sway generates CVT timings, not the old modelines). `HDMI1_1912x960_60` was bound in i3 but never implemented; it works now. |
| `eDP1_primary`, `HDMI1_primary`, `select_display_as_primary` | emulated | See "Primary" below. |
| `select_display_position` | full | Right/left/above/below are computed from logical rects. Negative coordinates shift the reference output instead. Custom X,Y input is kept. |
| `select_display_mode` | full | Lists `.modes[]` as `WxH@R.RRRHz`, plus `off`. |
| `select_display_orientation` | full | normal→`normal`, left→`270`, right→`90`, inverted→`180` |
| `select_display_scale` | full | `output X scale S`. Note the meaning flips: on sway a value above 1 makes things **larger** (xrandr `--scale 0.8` is roughly sway `1.25`). |
| `select_input_to_output` | full | Uses `swaymsg -t get_inputs` (pointer/touchpad/touch/tablet_tool), then `input <identifier> map_to_output <out>`. |
| `show_display_layout` | full | Notification listing name, mode, position, scale and transform; the focused output is marked `*`, and the primary output is shown. |

**Primary:** sway has no primary output, so the script emulates one:
1. It writes the output name to `$XDG_RUNTIME_DIR/sway_primary_output`.
2. It runs `workspace number 1; move workspace to output X; focus output X`.
3. When `xrandr` and `$DISPLAY` exist, it also runs `xrandr --output X --primary` for XWayland clients (best effort).

**Desktop profile:** `DP-1` 1920x1080 at `transform 180`, pos 0,840; `DP-2` 1920x1200 at scale 1.25, pos 0,1920;
`HDMI-A-1` 1920x1080 at scale 1.25, `transform 90`, pos 1920,0. This gives the same logical layout as
xrandr `--scale 0.8` and `--scale-from 1536x864`. The per-output `--brightness 0.9` is **dropped**
(use `ddcutil`, see the backlight operator).

**After every operation:** if the 2nd argument is `enable`, it runs `sway_conky_monitor_display.sh primary_only`
(replaces killall + i3-msg exec conky). The wallpaper is reset with
`swaymsg output * bg ~/.config/i3/share/default_wallpaper fill`. There is no picom step.

Suggested kanshi config (`~/.config/kanshi/config`), not installed; replace the monitor descriptions with real ones from `swaymsg -t get_outputs`:

```
profile laptop {
    output eDP-1 enable mode 1920x1080 position 0,0 scale 1
}
profile office {
    output eDP-1 enable position 0,0
    output "<Make Model Serial of office monitor>" enable mode 1920x1080 position 1920,0
    exec swaymsg "workspace number 1, move workspace to output HDMI-A-1"
}
profile home {
    output DP-1 enable mode 1920x1080 position 0,840 transform 180
    output DP-2 enable mode 1920x1200 position 0,1920 scale 1.25
    output HDMI-A-1 enable mode 1920x1080 position 1920,0 scale 1.25 transform 90
}
```
If kanshi runs as a daemon it will also react to hotplug and can replace `auto` at startup. Don't run both
kanshi and `sway_display_operator.sh auto` on every hotplug, or they will fight.

## 2. `sway_backlight_operator.sh <op> [level]`

| subcommand | status | notes |
| --- | --- | --- |
| `inc_xbacklight N`, `dec_xbacklight N` | full | `brightnessctl set +N%` / `N%-` (`-n1` stops the panel switching fully off) |
| `set_xbacklight L`, `set_xbacklight_with_rofi` | full | Converts the percentage to a raw value. Any L above 0 keeps at least 1 raw step, so `0.1` means minimum brightness, not off (like xbacklight). |
| `show_xbacklight` | full | `brightnessctl -m`; same replace-ID notification as before |
| `set_focused_display_backlight_with_rofi` | partial | Internal panel: brightnessctl. External monitor: `ddcutil --display N setvcp 10 L` (the DRM connector is matched through `ddcutil detect --terse`). If that fails: `gammastep -O <K> -b <L/100>`, which dims **all outputs** (wlroots gamma is global per client) and keeps the colour temperature of a running `sway_nightlight.sh`. |
| `set_all_connected_displays_backlight_with_rofi` | partial | Same per-output logic, with at most one gammastep fallback. |

ddcutil needs the `i2c-dev` module loaded and the user in the `i2c` group (`sudo usermod -aG i2c $USER`).

## 3. `sway_keyboard_operator.sh <op>`

All XKB tweaks are combined into **one generated keymap**:
`include "pc+us+inet(evdev)[+ctrl(nocaps|swapcaps)]"` plus `key <ESC>/<TLDE>/<BKSP>/<BKSL>` overrides.
It is applied with `swaymsg input type:keyboard xkb_file $XDG_RUNTIME_DIR/sway_keyboard.xkb`.
State in `sway_keyboard_state` lets the tweaks stack the way the old cumulative xmodmap/setxkbmap calls did.
Layout and model can be overridden with `SWAY_XKB_LAYOUT` (default `us`) and `SWAY_XKB_MODEL` (default `pc105`).
The keymap was checked with `xkbcomp`. If `xkbcli` (libxkbcommon-tools) is installed, it validates the keymap before applying it.
**Note:** `xkb_file` overrides any `xkb_layout`/`xkb_options` set for keyboards in `sway_input_output.config`
once `default` has run (it runs at startup via exec_always).

| subcommand | status | notes |
| --- | --- | --- |
| `speed_up_repeat_key_rate` / `restore_repeat_key_rate` | full | `repeat_delay 220` / `repeat_rate 50`; `660` / `25` |
| `send_capslock_key` / `send_numlock_key` | partial | `wtype -k Caps_Lock` / `Num_Lock`. wtype sends through a separate virtual keyboard. Whether the seat's lock LED and state toggle depends on the compositor; with sway it usually toggles for the focused client. |
| `map_capslock_to_ctrl` / `swap_capslock_with_ctrl` / `restore_capslock` | full | `ctrl(nocaps)` / `ctrl(swapcaps)` / none. The old restore used `ctrl:aa_ctrl`, which was really a different option; the port restores plain Caps Lock. |
| `swap_backslash_with_backspace` / `restore_…` | full | `<BKSP>`↔`<BKSL>` (X keycodes 22 and 51) |
| `swap_escape_with_grave` / `restore_escape_and_grave` | full | `<ESC>`↔`<TLDE>` (X keycodes 9 and 49) |
| `map_shift_escape_to_tilde` | full | `key <ESC> { [ Escape, asciitilde ] }` |
| `swap_escape_keybinding_with_grave_keybinding` | full | Swaps `+grave` and `+Escape` in `~/.config/sway/config.d/sway_workspace.config`, then `swaymsg reload`. Also edits `~/.config/libinput-gestures.conf` if it exists and restarts libinput-gestures. |
| `customize_tex_shinobi` / `restore_tex_shinobi` | full (assumed mapping) | X props `329` and `326` were taken to be libinput Accel Profile and Accel Speed. They map to `accel_profile flat` + `pointer_accel 0.80`, and `adaptive` + `0.0` for restore. Prop `315` was 0 in both and is ignored. The device is found by name `TEX-BLE-KB-N Mouse`. |
| `enable_tex_shinobi_trackpoint` / `disable_…` | full | `input <id> events enabled|disabled` |
| `restore_keyboard_layout` | full | Clears all tweaks and applies a plain `us` keymap |
| `default` | full | `ctrl(nocaps)` + Shift+Esc gives `~`, repeat 220/50, TEX customise if the device is present |

## 4. `sway_cursor_operator.sh <op> [pos]`

| subcommand | status | notes |
| --- | --- | --- |
| `move_cursor_inside_window [1-9|top_titlebar]` | full | Takes the focused node from `get_tree`: content box = `.rect` + `.window_rect`. Then runs `swaymsg seat - cursor set X Y`. |
| `enable_unclutter` / `disable_unclutter` | full | `seat * hide_cursor 3000` / `hide_cursor 0`. `--start-hidden` has no equivalent. |
| `set_unclutter_as_default` / `set_no_unclutter_as_default` | full | Edits a config line, see below |
| `enable_focus_follows_mouse` / `disable_…` | full | Edits `sway_window.config` and applies with swaymsg. It sets `mouse_warping output`/`none` as before, unless warping is `container` (mouse-follows-focus is on), which is left alone. |
| `enable_mouse_follows_focus` | full | `mouse_warping container` (native; replaces appending an exec to about 20 bindings) |
| `disable_mouse_follows_focus` | full | `mouse_warping output` if focus_follows_mouse is yes, otherwise `none` |

## 5. `sway_conky_monitor_display.sh <op>`

The user's conky configs are **never edited**. For each of `~/.config/conky/conky_config_{bindkey,system}`,
the script writes a copy to `$XDG_RUNTIME_DIR/sway_conky/`. In the copy it deletes the
`out_to_x`, `out_to_wayland`, `xinerama_head` and `own_window_type` lines, and inserts
`out_to_x = false, out_to_wayland = true,` after `conky.config = {`. Conky then runs on that copy.

**Choosing an output:** conky has no option to pick a Wayland output. A layer-shell surface opens on the
**focused** output, so the script focuses the target output, starts conky, waits `CONKY_MAP_DELAY`
(1.5 s), then gives focus back.

**Fallback:** if `conky -v` does not list Wayland (conky older than 1.19, or built without Wayland), it runs
the **unmodified** config under XWayland. Output selection is then impossible, and a notification says so.
`own_window_type override` windows appear unmanaged at the XWayland origin.

| subcommand | status |
| --- | --- |
| `all` | full (one pair of conky windows per active output) |
| `primary`, `default` | full (no `i3 restart`; "primary" = state file, else the output holding workspace 1, else the focused output) |
| `primary_only` | full |
| `eDP1` | full (the internal panel) |
| `bindkey_on`, `bindkey_off`, `system_on`, `system_off` | **new**: run or kill a single config. The kill pattern matches both the original and the patched path. |

## 6. KDE Connect

* `sway_kdeconnect_operator.sh`: `enable_pointer`, `disable_pointer`, `reload_pointer` and `reload_kdeconnect` work fully; the daemon is stopped with `pkill -f`.
  `pointer_invert_on` / `pointer_invert_off` are **stubbed**: they edited picom `invert-color-include`, and sway has no colour inversion. They show a notification and exit 1.
* `sway_kdeconnect_pointer_daemon.py`: the same i3ipc loop, but it matches the Wayland `app_id`
  (`org.kde.kdeconnect.daemon`, `kdeconnect.daemon`, `kdeconnectd`) as well as the XWayland class `kdeconnect.daemon`.
* **Limitation:** KDE Connect remote input (phone as touchpad or keyboard, presenter pointer) needs the
  xdg-desktop-portal **RemoteDesktop** interface on Wayland. `xdg-desktop-portal-wlr` does not implement it, so
  remote input on sway may not work at all. Pairing, notifications, clipboard, file sharing and media control are unaffected.
  The sway window rule should match `app_id="org.kde.kdeconnect.daemon"` as well as `class="kdeconnect.daemon"`.

## 7. Audited, not ported

* `i3_languagechanger.sh`: only calls the `ibus engine` / `ibus list-engine` CLI over D-Bus, which works on sway.
  Input in native Wayland apps depends on the IM module: GTK uses `GTK_IM_MODULE=ibus` over D-Bus, Qt uses `QT_IM_MODULE=ibus`.
  sway's text-input-v3/input-method-v2 support is better with fcitx5. **Reuse as `$I3_SCRIPT/i3_languagechanger.sh`.**
* `i3_conky_valuechanger.sh`: only edits the conky config files with sed and reads defaults
  (`default_conky_*`, `default_i3bar_*`) from `~/.config/i3/config`. No X dependency, so **reuse as-is**.
  Caveat: defaults come from the i3 config, not `~/.config/sway/config`. Changes take effect at the next conky
  start, because the helper re-copies the configs on every launch.
* `i3_genereate_conky_system_config.py`: prints a config to stdout; only calls `nvidia-smi`. **Reuse as-is.**
  The X-only `own_window_*` keys it emits are harmless because the helper patches the copy.

## 8. What the sway config must use or change

* Replace `$I3_SCRIPT/i3_{display,backlight,keyboard,cursor}_operator.sh`, `i3_conky_monitor_display.sh` and
  `i3_kdeconnect_operator.sh` with `$SWAY_SCRIPT/sway_*.sh`, keeping the same arguments.
* Startup: `exec $SWAY_SCRIPT/sway_display_operator.sh auto $default_conky_startup` and
  `exec_always $SWAY_SCRIPT/sway_keyboard_operator.sh default`.
* `sway_custom.config` conky modes: replace the raw `exec conky -c $HOME/.config/conky/conky_config_bindkey` and
  `exec kill $(pgrep -f "conky -c …")` bindings with `$SWAY_SCRIPT/sway_conky_monitor_display.sh bindkey_on|bindkey_off|system_on|system_off`.
  Raw conky on X configs would run under XWayland.
* `sway_mode.config` lines that run `unclutter`/`killall unclutter` should call
  `$SWAY_SCRIPT/sway_cursor_operator.sh enable_unclutter|disable_unclutter`.
* Do **not** append `exec … move_cursor_inside_window` to focus, move or resize bindings; `mouse_warping container`
  replaces that. The explicit `move_cursor_inside_window 1..9` bindings stay.
* **Lines the scripts edit at runtime** (the first matching line is replaced; it may be commented out with `#`):
  * `config.d/sway_input_output.config` (searched first) or `config.d/sway_startup.config`:
    `seat * hide_cursor 3000` (on) / `#seat * hide_cursor 3000` (off). Regex: `^\s*#?\s*seat\s+\*\s+hide_cursor\s+[0-9]+`.
    If neither file has such a line, `set_*unclutter_as_default` shows an error notification.
  * `config.d/sway_window.config`: `focus_follows_mouse yes|no` and `mouse_warping output|none|container`
  * `config.d/sway_workspace.config`: every `+grave` / `+Escape` is swapped (swap_escape_keybinding…)

## 9. Packages

| purpose | Ubuntu 24.04 (apt) | Fedora (dnf) |
| --- | --- | --- |
| IPC / parsing | `sway jq bc psmisc procps util-linux` | `sway jq bc psmisc procps-ng util-linux` |
| output tools | `wlr-randr kanshi wl-mirror wdisplays` | `wlr-randr kanshi wl-mirror wdisplays` |
| backlight | `brightnessctl ddcutil gammastep` | `brightnessctl ddcutil gammastep` |
| keyboard | `wtype libxkbcommon-tools` | `wtype libxkbcommon-utils` |
| conky | `conky-all` (check `conky -v \| grep -i wayland`) | `conky` |
| menus / notify | `rofi` is 1.7.x and X-only on 24.04: build `rofi` 2.x or `rofi-wayland` from source or a PPA; `libnotify-bin` | `rofi-wayland` (or rofi ≥ 2.0), `libnotify` |
| kdeconnect | `kdeconnect python3-i3ipc` | `kde-connect python3-i3ipc` |
