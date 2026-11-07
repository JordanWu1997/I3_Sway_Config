# 01 — Configuration Conversion Record (i3 → sway)

This file records, file by file, how every part of `config/i3` was converted to
`config/sway`. Each place in the sway files where something differs from i3 has a `[SWAY]`
comment.

Status legend:

| Status | Meaning |
| :-- | :-- |
| ✅ Same | Copied unchanged. sway parses it exactly like i3. |
| 🔁 Converted | Same behaviour with a different command or tool. |
| ⚠️ Partial | Works, with a documented limitation. |
| ❌ Not possible | No sway/Wayland equivalent. Kept commented out with the reason. |

## How the conversion was done

1. **Mechanical pass.** Each `config/i3/config.d/i3_*.config` was transformed into
   `config/sway/config.d/sway_*.config`:
   - Paths and the vim modeline were changed (`ft=swayconfig`).
   - `exec --no-startup-id` became `exec`. sway accepts the flag, but only to log a
     warning that it is ignored (`sway/commands/exec_always.c`).
   - Calls to X11-dependent scripts were redirected from `$I3_SCRIPT/i3_*.sh` to their
     Wayland ports in `$SWAY_SCRIPT/sway_*.sh`.
   - `xdotool key …` became `wtype …`.
   - `xdotool mousemove/click` became native `seat - cursor …` commands.
   - `redshift -m randr` became `sway_nightlight.sh` (gammastep).
   - Unquoted `mode $mode_x` became `mode "$mode_x"`.
2. **Hand pass.** Everything that needed a different design was rewritten by hand: the
   startup file, the new input/output file, colors, windows, bar, screenshots, locking and
   the system mode.
3. **Static verification.** A checker parsed the whole include tree. It checked:
   - duplicate bindings per mode (sway shows a swaynag warning for those)
   - undefined modes and variables
   - unknown top-level commands
   - missing scripts

   It also replays sway's variable substitution, which found the problem described in
   "Mode-name variables" below. Final result: **0 problems**, 2,522 config lines,
   103 modes, 1,879 bindings.
   > The checker is static. sway is not installed on this machine, so `sway -C` was
   > **not** run. Run `sway -C -c ~/.config/sway/config` after installing.

## File map

| i3 file | sway file | Notes |
| :-- | :-- | :-- |
| `config` | `config` | Hand-written. Adds `$I3_SCRIPT`/`$SWAY_SCRIPT`, sway monitor names and the pywal include in place of `set_from_resource`. |
| — | `config.d/sway_input_output.config` | **New.** Replaces xrandr, setxkbmap, xset, numlockx, imwheel, unclutter and libinput-gestures. |
| — | `config.d/sway_mode_name.config` | **New.** All 103 `set $mode_*` labels, moved here (see "Mode-name variables"). |
| `i3_window.config` | `sway_window.config` | Mechanical + hand edits (app_id rules, `tiling_drag`, `title_window_icon`). |
| `i3_workspace_name.config` | `sway_workspace_name.config` | ✅ Same. |
| `i3_workspace.config` | `sway_workspace.config` | Mechanical (script paths only). |
| `i3_gap.config` | `sway_gap.config` | Mechanical. All gap commands exist in sway. |
| `i3_bindkey.config` | `sway_bindkey.config` | Mechanical + hand edits. |
| `i3_mode.config` | `sway_mode.config` | Mechanical + hand edits (vim/mouse/system/display/backlight/recording modes). |
| `i3_custom.config` | `sway_custom.config` | Mechanical + hand edits (picom → opacity). |
| `i3_bar.config` | `sway_bar.config` | Mechanical + `tray_output`. |
| `i3_startup.config` | `sway_startup.config` | Hand-written (most entries were X11 daemons). |
| `i3_iOS_compatibility.config` | `sway_iOS_compatibility.config` | Mechanical. Mod5 works the same. |

## Cross-cutting changes

### Variables and environment

| i3 | sway | Status |
| :-- | :-- | :-- |
| `$I3_SCRIPT` came from `~/.profile` (environment) | `set $I3_SCRIPT $HOME/.config/i3/script` and `set $SWAY_SCRIPT $HOME/.config/sway/script` in `config` | 🔁 Your old sway README noted that sway did not load `~/.profile`. The cause: the display manager runs the session through your login shell, which is fish, and fish never reads `~/.profile`. The config now defines both paths itself, and `script/sway_session.sh` sources `~/.profile` before starting sway. |
| `$BROWSER`, `$WALLPAPER1..9`, `$WALLPAPERI3/V/D/F` (environment) | Unchanged references | ⚠️ These need the session launcher (`sway-session`) so `~/.profile` is loaded. |
| `$monitor2 HDMI-0`, `$monitor4/5 VIRTUAL-1/2` | `HDMI-A-1`, `HEADLESS-1/2` | 🔁 sway uses DRM connector names. Check yours with `swaymsg -t get_outputs`. |

### Mode-name variables (found by the checker)

i3 substitutes `$variables` in a pre-pass over the whole file, so a binding can
reference a mode label defined further down. sway substitutes **line by line**, and uses
the **longest variable already defined** (`sway/commands.c`, `config_command()`).

Example: `bindsym o mode "$mode_gaps_outer"` appears before `set $mode_gaps_outer …`.
sway matches the shorter `$mode_gaps` and binds the mode name `Gaps: … _outer`, which
does not exist.

The same pattern affected:

- `$mode_display_preset`
- `$mode_dunst_logger` / `_option` / `_position`
- `$mode_titlebar_fontsize` / `_style`
- `$mode_border_*`
- `$mode_conky_*`
- `$mode_i3bar_option`

**Fix:** all 103 `set $mode_*` lines were moved to `config.d/sway_mode_name.config`, which
is included before any file that binds a mode. Each mode block keeps a comment pointing
there.

### Colors (`set_from_resource`)

| i3 | sway | Status |
| :-- | :-- | :-- |
| `set_from_resource $cN i3wm.colorN #fallback` (X resource database filled by pywal) | `include ./share/colors-sway-fallback`, then `include ~/.cache/wal/colors-sway-i3` | 🔁 Full. pywal renders the user template `share/wal_templates/colors-sway-i3` into `set $bg/$fg/$c0..$c15` lines. A missing include is silently skipped (`load_include_config` returns false without error), so the fallback values apply on the first start. Like i3, colors only update when the config is re-read: `sway_wal_operator.sh` runs `swaymsg reload`. |
| `exec wal --nine -s -t -i default_wallpaper` | `exec wal --nine -n -s -t -i …` + `output * bg … fill` | 🔁 `-n` stops wal from calling feh. sway sets the wallpaper itself through swaybg. |
| `client.background $transp` | Kept | ⚠️ Accepted and ignored by sway (`cmd_client_noop`). The background behind windows is always the wallpaper/output. |
| `client.placeholder …` | Kept | ⚠️ Accepted and ignored: sway has no placeholder windows. |

### Unquoted mode names

`bindsym … mode $mode_workspace` (unquoted, multi-word label) was quoted everywhere. sway
splits an unquoted variable value into several arguments, so the mode would not be found.

## Per-file details

### `config` (main)

| i3 | sway | Status |
| :-- | :-- | :-- |
| Variables block (`$default_*`, `$terminal`, …) | Same names, same `set $name value` shape | ✅ `sway_default_valuechanger.sh` edits them in place, as the i3 script did. |
| Color block | See "Colors" above | 🔁 |
| `include ./config.d/*.config` | Same, plus `sway_input_output.config` and `sway_mode_name.config` | ✅ sway resolves relative includes against the including file's directory. |

### `sway_window.config`

| i3 line(s) | sway | Status |
| :-- | :-- | :-- |
| `client.*` palette | Same | ✅ |
| `for_window [window_role=…]`, `[window_type=…]` | Kept, labelled "XWayland only" | ⚠️ Native Wayland windows have neither property. sway already floats native dialogs (toplevels with a parent or fixed size). An extra rule floats `xdg_shell` Open/Save/Choose file dialogs. |
| `for_window [class=…] floating enable` (37 rules) | Kept, plus 30 `[app_id=…]` rules | 🔁 `class` only matches XWayland windows. Each GTK/Qt/kitty app that is now native gets its app_id rule, e.g. `floating_terminal` (kitty `--class` sets the app_id), `org.gnome.Nautilus`, `org.gnome.Calculator`, `pavucontrol`/`org.pulseaudio.pavucontrol`, `blueman-manager`, `nm-connection-editor`, `org.gnome.Evince`, `org.gnome.eog`/`org.gnome.Loupe`, `org.kde.kdeconnect.*`, `thunar`, `nl.hjdskes.gcolor3`, `org.rncbc.qjackctl`, plus new tools (`wdisplays`, `swappy`, `imv`, `showmethekey-gtk`). The class rules stay for apps that still run through XWayland (Steam, Zoom, VirtualBox, TeamViewer, Tk, feh, Xmag, Gpick, Florence…). |
| `for_window [title="^Figure*"]` | Kept + `[title="^Figure \d+"]` | ✅ Matches both backends. |
| `for_window [title="Picture-in-Picture"] sticky enable` | Kept + Firefox app_id rule that also floats | ✅ |
| `focus_on_window_activation smart` | Same | ✅ Applies to xdg-activation and XWayland. |
| `focus_wrapping yes`, `popup_during_fullscreen smart`, `default_orientation auto`, `workspace_layout default` | Same | ✅ |
| `for_window [tiling]/[floating] border …`, `default_border`, `default_floating_border` | Same | ✅ |
| `hide_edge_borders smart_no_gaps` | Same | ✅ |
| `font pango: …`, `title_format "%title"`, `title_align center`, `show_marks yes` | Same | ✅ |
| `for_window [all] title_window_icon padding 5px` | Commented out | ❌ i3-only feature (icons in titlebars). Not in sway's command table. |
| `tiling_drag modifier titlebar` | `tiling_drag enable` (+ `tiling_drag_threshold 9`) | 🔁 sway's `tiling_drag` takes only a boolean. When enabled, both titlebar drag and modifier drag work. Leaving the i3 arguments in would have parsed as "disable". |
| `tiling_drag swap_modifier Shift` | Commented out | ❌ Not implemented in sway. Use the swap bindings (`Mod4+semicolon`, `Mod4+Shift+y`). |
| `floating_modifier Mod4` | `floating_modifier Mod4 normal` | ✅ Same behaviour, explicit button order. |
| `focus_follows_mouse yes`, `mouse_warping output` | Same | ✅ `mouse_warping container` is also available (see 03). |
| `[con_mark='] focus`, `swap container with mark '`, `[urgent=latest] focus` | Same | ✅ The `'` mark is maintained by the shared automark daemon (i3 IPC over `$I3SOCK`). |

### `sway_workspace_name.config`, `sway_workspace.config`, `sway_gap.config`

All workspace commands are supported by sway:

- `workspace … output …`
- `workspace next/prev/back_and_forth`
- `move container|workspace to output …`
- `focus output …`
- `workspace_auto_back_and_forth`

All gap commands are supported too: `gaps inner|outer|horizontal|vertical|top|right|bottom|left current|all set|plus|minus`
and `smart_gaps on|off|inverse_outer` (checked in `sway/commands/gaps.c` and `smart_gaps.c`).

The only changes were script paths. **Status ✅/🔁.**

### `sway_bindkey.config`

| i3 binding | sway | Status |
| :-- | :-- | :-- |
| `Mod4+r reload` | Same | ✅ |
| `Mod4+Shift+r restart` | `reload` | 🔁 sway has no `restart`. It never needed one: `reload` re-reads the config and re-runs `exec_always` without losing windows. |
| App launchers `Ctrl+Mod1+1..=` | Same | ✅ (see 04 for which run natively) |
| Volume / media keys (`pactl`, `playerctl`) | Same | ✅ No X dependency. |
| `XF86MonBrightness*` (`xbacklight`) | `sway_backlight_operator.sh` (brightnessctl) | 🔁 |
| `Mod4+d` / `Mod4+Shift+d` rofi drun/run | Same | ✅ Needs a Wayland-capable rofi (≥ 2.0 or rofi-wayland). |
| `Mod1+Tab` `rofi -show window`, `Mod1+q` `rofi -show windowcd` (thumbnails) | `sway_window_switcher.sh all` / `same_app` | ⚠️ rofi's X11 window modes only see XWayland windows. The new script lists windows from the sway tree. **Window thumbnails are lost.** |
| Scratchpad selector, file browser, omnisearch, `Mod4+?` keybinding page, rofi `keys` | Same (omnisearch → `sway_rofi_omnisearch.sh`) | ✅ The omnisearch keybinding page parses the sway files. |
| `XF86Display arandr` | `wdisplays` | 🔁 |
| `Ctrl+Mod1+q` `i3-nagbar … i3-msg exit` | `swaynag … swaymsg exit` | 🔁 |
| `Mod4+o exec i3-msg open` | Commented out | ❌ sway has no `open` (empty placeholder container). |
| Focus/move/resize/fullscreen/floating/sticky/layout/split/border/marks/automarks/scratchpad | Same commands | ✅ (`fullscreen toggle global`, `layout toggle splitv splith tabbed stacking`, `border toggle N` all exist in sway) |
| `… exec i3_cursor_operator.sh move_cursor_inside_window` after focus/move | `sway_cursor_operator.sh` (`seat - cursor set`) | 🔁 |
| `dunstctl …` | Same | ✅ dunst runs natively on Wayland. |
| `Ctrl+Mod1+space` ibus engine switch, `Shift+space` notice | Same | ⚠️ See 03 "Input method". |
| `Print` flameshot, `Mod4+Print` / `Mod4+Shift+Print` gnome-screenshot | `sway_screenshot_operator.sh GUI` / `active_window` / `select_window` | 🔁 grim + slurp + swappy. |
| `button2/3` nop, `--release button2 kill`, `--whole-window Mod4+button2/3`, `--border button4/5` | Same | ✅ sway supports `--release`, `--whole-window` and `--border` on mouse buttons. |
| `Ctrl+button8/9` unclutter on/off | `seat * hide_cursor 3000` / `0` | 🔁 Native. |
| `Mod1+m` warpd | Same | ⚠️ warpd must be built with `PLATFORM=wayland`. |

### `sway_mode.config` (per mode)

| Mode | Change | Status |
| :-- | :-- | :-- |
| Insert mode | None | ✅ Still the escape hatch for VMs/remote desktops/games. Native Wayland apps can also request `shortcuts_inhibitor`. |
| Vim keybinding mode | `xdotool key [--clearmodifiers] X` → `wtype [-M mod] -k X [-m mod]` | 🔁 wtype has no `--clearmodifiers`. The bindings are already `--release`, so physical modifiers are up when the key is sent. |
| Mouse mode | `xdotool mousemove_relative` → `seat - cursor move`. `click/mousedown/mouseup N` → `seat - cursor press/release buttonN`. Scroll (4–7) → `seat - cursor press button4..7`, which sway sends as axis events (`sway/commands/seat/cursor.c`). Repeated scrolls → loop or chained commands. | 🔁 Native, no daemon. |
| Mouse mode `Ctrl+Shift+u/i/o` (Shift+drag) | `ydotool key 42:1` + `seat cursor press` | ⚠️ A held modifier needs ydotool (ydotoold + /dev/uinput). |
| Mouse mode `m` magnus, misc `6` xzoom | woomer if installed, else a notification | ⚠️ X11 magnifiers cannot capture Wayland windows. No packaged Wayland zoomer. |
| Cursor preference mode | `sway_cursor_operator.sh` (unclutter → `hide_cursor`, mouse_follows_focus → `mouse_warping container/none`) | 🔁 |
| System mode | `Shift+e` → `exit`. `Shift+l` `xset dpms force off` → `output * power off` via a one-shot swayidle that powers outputs back on at resume (sway does not wake outputs on input by itself). Lock → `loginctl lock-session` (handled by swayidle). Suspend → `sway_lock_operator.sh`. | 🔁 |
| Network mode `r` | `nm-applet` → `nm-applet --indicator` | 🔁 swaybar's tray is SNI-only. |
| Bluetooth / RF / Terminal modes | Same. Terminal mode adds `[6] foot`. urxvt/xterm run through XWayland. | ✅ |
| Toolkit / Capture modes | `sway_toolkit_operator.sh`: color picker (grim + slurp + ImageMagick), OCR (tesseract), QR (zbarimg), clipboard via wl-copy | 🔁 |
| Screenshot mode | `sway_screenshot_operator.sh`, same 0–4 / Shift keys | 🔁 |
| Recording mode | peek → `sway_recorder.sh toggle region/output` (wf-recorder). screenkey → `showmethekey-gtk`. | 🔁 |
| Misc tool mode | `kill_window` (xkill) → slurp-selected window. xzoom → woomer. | ⚠️ |
| Caffeine modes | `sway_toolkit_operator.sh enable/disable_caffeine` (swayidle instead of `xset s off -dpms`) | 🔁 |
| Keyboard / non-HHKB / HHKB / TEX modes | `sway_keyboard_operator.sh` (setxkbmap/xmodmap/xset/xinput → `swaymsg input …`) | 🔁/⚠️ (see that script's report) |
| Tool reload mode | parcellite → cliphist watcher. libinput-gestures → native `bindgesture`. | 🔁 |
| KDE Connect mode | `sway_kdeconnect_operator.sh` | ⚠️ Remote input is not possible on wlroots (see 03). |
| Display / preset / eDP1 / HDMI1 modes | `sway_display_operator.sh` (`swaymsg output`). arandr → wdisplays. | 🔁 "primary" and "mirror" are emulated (see the script report). |
| Backlight mode | brightnessctl. xrandr software brightness → gammastep/ddcutil. | 🔁 |
| Redshift mode | `sway_nightlight.sh set <K>/off` (gammastep). On Wayland the gamma resets when the client exits, so one gammastep process stays running. | 🔁 |
| Dunst / Dunst logger modes | Same | ✅ |
| Player / Spotifyd / Mpv / Audio modes | Same | ✅ No X dependency (playerctl/pactl/pulsemixer). |
| Resize mode | Same commands | ✅ |
| Titlebar mode | `i3-msg title_format $(rofi …)` → `swaymsg title_format "$(rofi -l 0 …)"` | 🔁 |
| Mark / Automark modes | `sway_mark_operator.sh` (i3-input → rofi) | 🔁 |
| Window layout / Autotiling modes | `sway_window_operator.sh`. autotiling supports sway. | 🔁 |
| Workspace / Swap / Save / Restore modes | `sway_workspace_operator.sh` | ⚠️ sway has no `append_layout`, so layouts cannot be restored (see script report). |
| Open URL / AI / Research modes | Same | ✅ |
| Open URL `c` → `$mode_clink` | Commented out | ❌ **Existing i3 bug:** `$mode_clink` is never defined in the i3 config either (also flagged in `i3/doc/workflow/I3_WORKFLOW_FSM.md`). |

### `sway_custom.config`

| Mode | Change | Status |
| :-- | :-- | :-- |
| Wallpaper mode (feh backend) | `sway_wallpaper_operator.sh feh …` → `swaymsg output * bg`. The backend argument is kept. | 🔁 |
| Variety mode | Same subcommands | ✅ Variety supports sway (swaybg). |
| Border width / default / option / colorscheme | Native commands + ported scripts | ✅/🔁 |
| Dunst option modes | Same | ✅ |
| Conky modes | `conky -c …` unchanged. Display helper → `sway_conky_monitor_display.sh` (Wayland-patched copy, `out_to_wayland`). | ⚠️ Needs conky ≥ 1.19 built with Wayland. |
| Theme mode (pywal) | `sway_wal_operator.sh` (+ `swaymsg reload`) | 🔁 |
| Reload mode | `sway_reload_operator.sh`. `xsslock` → swayidle. `Xresources` kept (only XWayland apps read it). | 🔁 |
| Picom / default picom | `sway_opacity_operator.sh` (sway `opacity`). `0` killall picom → `off`. | ⚠️ Transparency is full. **Blur needs SwayFX.** |
| Flashfocus modes | `sway_flashfocus_operator.sh` | ✅ flashfocus supports sway IPC directly. |
| Font mode | `sway_default_valuechanger.sh` | 🔁 |

### `sway_bar.config`

| i3 | sway | Status |
| :-- | :-- | :-- |
| Two `bar {}` blocks (`bar_status`, `bar_mode`) with `position`, `mode`, `hidden_state`, `height`, `modifier`, `binding_mode_indicator`, `font`, `workspace_buttons`, `workspace_min_width`, `strip_workspace_*`, `tray_padding`, `colors {}` | Same | ✅ swaybar implements the i3bar options. |
| `status_command bumblebee-status …` (multi-line with `\`) | Same | ✅ swaybar speaks the i3bar protocol. sway supports `\` line continuation (`getline_with_cont`). |
| `tray_output primary` | `tray_output *` | 🔁 There is no primary output on Wayland. |
| Tray icons | — | ⚠️ swaybar shows only StatusNotifierItem icons, not XEmbed (see 04). |
| `bindsym Ctrl+Mod1+b bar mode toggle bar_mode` | Same | ✅ sway accepts i3's `bar mode <m> <id>` order at runtime (`sway/commands/bar.c`). |
| Bar mode/option/fontsize/height/theme modes | `sway_bar_operator.sh`, `sway_default_valuechanger.sh`, `sway_bar_decorator.sh` | 🔁 |

### `sway_startup.config`

| i3 startup item | sway | Status |
| :-- | :-- | :-- |
| — | `dbus-update-activation-environment --systemd …` + `systemctl --user import-environment …` | **New, required.** Without it, xdg-desktop-portal (screen sharing), D-Bus-activated services and flatpak apps never see `WAYLAND_DISPLAY`. |
| `echo $PATH > /tmp/i3-path` | `/tmp/sway-path` | ✅ |
| memory notifier, notify logger | Shared i3 scripts | ✅ |
| `i3_display_operator.sh auto` | `sway_display_operator.sh auto` (or kanshi) | 🔁 |
| `xsettingsd` | Kept (XWayland apps) + `sway_import_gsettings.sh` (native GTK) | 🔁 |
| workspace name list | `sway_genereate_workspace_name_list.sh` | 🔁 |
| polkit-gnome, blueman-applet, kdeconnect-indicator, dunst, autotiling, automark daemon | Same | ✅ |
| `nm-applet` | `nm-applet --indicator` | 🔁 |
| `numlockx on` | `xkb_numlock enabled` | 🔁 |
| `imwheel -b 45` | `scroll_factor 1.5` | ⚠️ Global factor; imwheel's per-button/per-app rules have no equivalent. |
| `xset m 2/1 4` | `accel_profile adaptive` + `pointer_accel 0.3` | 🔁 Approximate. libinput uses a different acceleration model, so tune the value. |
| `i3_keyboard_operator.sh default` | `repeat_delay 220` / `repeat_rate 50` / `ctrl:nocaps` in input config + `sway_keyboard_operator.sh default` | 🔁 |
| caffeine | `sway_toolkit_operator.sh enable_caffeine` | 🔁 |
| `libinput-gestures-setup start` | 18 `bindgesture` lines (same actions, called directly instead of faking keys) | 🔁 2-finger pinch is left unbound on purpose: Wayland apps zoom natively. |
| `ibus-daemon -r -d -x` | Kept. `fcitx5` alternative commented next to it. | ⚠️ See 03. |
| parcellite | cliphist via `sway_toolkit_operator.sh reload_parcellite` | 🔁 |
| flashfocus (waited for picom) | `sway_flashfocus_operator.sh start` | ✅ |
| `flameshot` daemon | Removed (grim/slurp run on demand) | 🔁 |
| `unclutter` | `seat * hide_cursor 3000` | 🔁 |
| battery popup (i3-nagbar) | `sway_battery-popup.sh` (swaynag) | 🔁 |
| picom after restart | `sway_opacity_operator.sh after_i3_restart` | 🔁 |
| `i3_xsslock_operator.sh` (xss-lock + i3lock) | `sway_idle_operator.sh current_desktop` (swayidle + swaylock) | 🔁 |
| login summary | `sway_system_status.sh login` | 🔁 |

### `sway_input_output.config` (new)

This file is the declarative replacement for tools that X11 needed at runtime. The
mapping table is in the header of the file. Highlights:

- Keyboard: `xkb_options ctrl:nocaps`, repeat 220/50, NumLock on.
- Pointer and touchpad: tap, natural scroll, disable-while-typing, middle-button emulation.
- Cursor hiding after 3 s and while typing.
- Lid switch: disable the internal panel while the lid is closed.
- Native touchpad gestures reproduce every action from `config/libinput-gestures.conf`.

## Keysym bindings: `plus` → `equal` (test_v2)

i3 resolves a `bindsym` keysym to the **key** that produces it, so i3's `Mod4+plus` fired on
Super+`=` without Shift. sway matches the **keysym produced** by the key press. `Mod4+plus`
would need Super+Shift+`=`, and `Shift+plus` never matches, because sway drops the consumed
Shift before matching. All 20 `plus` bindings without Shift became `equal`, and
`Shift+plus` became `Shift+equal`. The brightness and volume modes pair `minus` with
`equal` again. No other shifted keysym (`question`, `underscore`, …) is bound with a
modifier. Unmodified mode bindings like `question` still work, because the translated
keysym matches.

