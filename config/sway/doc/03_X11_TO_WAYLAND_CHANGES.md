# 03 — What Must Change When Moving from X11 to Wayland

i3 is a window manager *running on* an X server. Any X client can read the screen, read
every keystroke, move any window and inject input. That is why tools like xdotool,
xrandr, flameshot and xkill work under i3.

sway is a Wayland *compositor*. It is display server, window manager and compositor in
one process. Clients are isolated from each other. Anything global (screenshots, input
injection, output configuration, gamma, idle, clipboard history) must go through sway or
through a dedicated Wayland protocol that sway implements.

The sections below are ordered by how badly things break if you skip them.

---

## 1. Blocking items (sway will not start, or the session is unusable)

### 1.1 Distribution version
- **This machine runs Pop!_OS 22.04 LTS.** Its repositories ship **sway 1.7**. This
  config needs sway ≥ 1.9:
  - `bindgesture` needs 1.8
  - `smart_gaps inverse_outer` needs 1.8
  - input-method popups need 1.10
  - many wlroots fixes for NVIDIA came later
- Options:
  - upgrade to Pop!_OS/Ubuntu 24.04 (sway 1.9)
  - use Fedora (sway 1.10+)
  - build sway + wlroots from source

  `installation/install_sway.sh` warns and stops on 22.04.

### 1.2 NVIDIA proprietary driver (detected on this machine: `nvidia_drm` is loaded)
- sway refuses to start on the proprietary driver unless launched with
  `sway --unsupported-gpu`. `sway-session` (`script/sway_session.sh`) adds the flag
  automatically when `/sys/module/nvidia_drm` exists.
- Kernel mode setting is required: `nvidia-drm.modeset=1`. On Pop!_OS:
  `sudo kernelstub -a nvidia-drm.modeset=1`, then reboot.
- Driver ≥ 495 (GBM) is required. ≥ 555 (explicit sync) is strongly recommended:
  without it, XWayland apps flicker.
- The launcher sets `WLR_NO_HARDWARE_CURSORS=1`, which fixes an invisible or corrupt
  cursor on many driver versions. Remove it if your cursor is fine without it.
- If you have hybrid graphics (Intel/AMD iGPU + NVIDIA), the most reliable setup is to
  let sway render on the iGPU. Pop!_OS "hybrid" mode does this.
- Output names change from nvidia-X style (`HDMI-0`, `DP-0`) to DRM style (`HDMI-A-1`,
  `DP-1`). Update `$monitor1..5` in `config` with `swaymsg -t get_outputs`.

### 1.3 Session start and environment (`~/.profile` was not loaded)
- Under X11, i3 was started by Xsession scripts that source `~/.profile`. Wayland
  sessions are started by the display manager through your **login shell**. Your login
  shell is **fish**, which never reads `~/.profile`. So `$I3_SCRIPT`, `$WALLPAPER*`,
  `$BROWSER` and the IME variables were missing in sway. That was the first problem
  listed in your old sway README.
- Fix:
  - `script/sway_session.sh` is installed as `/usr/local/bin/sway-session`, with the
    login entry `share/sway-session.desktop` ("Sway (user session)").
  - It sources `~/.profile` and exports the Wayland toolkit variables.
  - It handles NVIDIA (1.2) and logs to `~/.local/state/sway.log`.
- `sway_startup.config` first runs `dbus-update-activation-environment --systemd …`.
  Without it, xdg-desktop-portal, flatpak apps and D-Bus-activated services (dunst,
  kdeconnectd) start without `WAYLAND_DISPLAY`. Screen sharing and file pickers then fail.

### 1.4 Toolkit environment variables (set by `sway_session.sh`)

| Variable | Why |
| :-- | :-- |
| `XDG_CURRENT_DESKTOP=sway`, `XDG_SESSION_TYPE=wayland` | Portal backend selection (`xdg-desktop-portal-wlr`), app heuristics |
| `QT_QPA_PLATFORM="wayland;xcb"` | Qt apps run natively (needs `qtwayland5`/`qt6-wayland`), fall back to XWayland |
| `GDK_BACKEND="wayland,x11"` | GTK 3/4 native with fallback |
| `SDL_VIDEODRIVER="wayland,x11"` | SDL2 programs (scrcpy, games) |
| `MOZ_ENABLE_WAYLAND=1` | Firefox (the default since 121; harmless) |
| `ELECTRON_OZONE_PLATFORM_HINT=auto` | Electron ≥ 28 apps (VS Code, Slack, Discord, Mailspring, ObinsKit) run natively |
| `_JAVA_AWT_WM_NONREPARENTING=1` | Java/Swing apps show blank grey windows on non-reparenting WMs otherwise |
| `XMODIFIERS=@im=ibus` | **Bug fix:** `default_profile` exports `XMODIFIER` (missing the S), so XWayland/X11 apps never connected to ibus. The launcher exports the correct name. Fix `config/i3/share/default_profile` too. |

---

## 2. Things that stop working silently unless replaced

| Area | X11 mechanism (i3 setup) | Wayland replacement (sway setup) | Notes |
| :-- | :-- | :-- | :-- |
| Window manager IPC | `i3-msg`, python `i3ipc` | `swaymsg` (same protocol); `i3-msg`/i3ipc keep working | sway exports `I3SOCK` and `SWAYSOCK` (verified in `sway/ipc-server.c`), so the shared i3 scripts work unchanged. |
| Window identity | `class`, `instance`, `window_role`, `window_type` (xprop) | `app_id` (native), `class` only for XWayland | Check with `swaymsg -t get_tree`. Every for_window rule got an app_id twin. |
| Display layout | xrandr, arandr, display operator presets | `output` blocks, `swaymsg output …`, wdisplays, **kanshi** for automatic profiles | No "primary" output. No true mirroring (`wl-mirror` shows one output's content in a window on another). |
| Keyboard layout and options | setxkbmap, xmodmap | `input type:keyboard xkb_*` | xmodmap keycode remaps → `xkb_file` or keyd (see the keyboard script report). |
| Key repeat, NumLock | `xset r rate`, numlockx | `repeat_delay`/`repeat_rate`, `xkb_numlock` | |
| Pointer speed, wheel speed | `xset m`, imwheel | `pointer_accel`/`accel_profile`, `scroll_factor` | imwheel per-app rules are gone. |
| Input device control | xinput | `swaymsg input <id> events disabled`, `map_to_output` | |
| Cursor hiding | unclutter | `seat * hide_cursor <ms>` / `when-typing` | |
| Gestures | libinput-gestures + xdotool | `bindgesture` | No daemon, no `input` group needed. |
| Fake input | xdotool (XTEST) | wtype (keys, virtual-keyboard), `seat - cursor` (pointer, built in), ydotool (uinput, for held modifiers) | wtype types into the focused window only. ydotool needs ydotoold + /dev/uinput. |
| Screenshots | flameshot, gnome-screenshot, `import` | grim (+ slurp to select, swappy to annotate) | Clients cannot read the screen. grim uses wlr-screencopy. |
| Screen recording | peek | wf-recorder | |
| Screen sharing (browser, Zoom, Teams, Discord, OBS) | Any X client could capture | **xdg-desktop-portal-wlr + PipeWire** | Needs (1.3). Zoom needs `enableWaylandShare=true` in `~/.config/zoomus.conf`. OBS: "Screen Capture (PipeWire)". xdg-desktop-portal ≥ 1.18 picks backends from `sway-portals.conf` (repo: `share/sway-portals.conf`, linked to `~/.config/xdg-desktop-portal/` by the installer). |
| Color picker | xcolor, gpick | grim + slurp + ImageMagick (`sway_toolkit_operator.sh pickup_color`) | gpick under XWayland only sees XWayland windows. |
| Clipboard | xclip/xsel, parcellite | wl-clipboard (`wl-copy`/`wl-paste`), cliphist | **On Wayland the clipboard content disappears when the source app closes**, unless a manager holds it. The cliphist watcher keeps history. Neovim picks `wl-copy` automatically when `$WAYLAND_DISPLAY` is set. **tmux:** change `xclip` to `wl-copy` in your tmux yank bindings. |
| Brightness | xbacklight, `xrandr --brightness` | brightnessctl (needs `video` group), ddcutil for external monitors | Software (gamma) dimming → `gammastep -b`. |
| Night light | redshift (randr) | gammastep / wlsunset | The gamma resets when the client exits, so one process stays running (`sway_nightlight.sh`). |
| Screen lock | i3lock + xss-lock | swaylock + swayidle | `loginctl lock-session` still works (swayidle `lock` event). |
| DPMS / screensaver / caffeine | `xset dpms`, `xset s off` | `output * power on/off`, swayidle timeouts, `inhibit_idle` | Outputs do **not** wake on input after a manual `power off`. Use swayidle `resume` (done in the system mode). |
| Video players keeping the screen awake | Players reset the X screensaver timer (`XResetScreenSaver`, `xdg-screensaver`) and xss-lock respected it | Wayland idle-inhibit protocol only | XWayland apps and some native apps never send it, so `sway_window.config` sets `inhibit_idle fullscreen` for every window. A video playing in a *non*-fullscreen window can still be locked: use caffeine mode. |
| Wallpaper | feh | `output * bg <file> fill` (swaybg) | pywal must run with `-n`. Variety supports sway. |
| Compositor effects | picom (opacity, blur, shadows, fading, rounded corners) | sway `opacity` built in | Blur, shadows, rounded corners and dim_inactive need **SwayFX**. No fading/animations. |
| Notifications | dunst | dunst ≥ 1.6 (layer-shell) | `follow = mouse` behaves differently (no global pointer query). Use `follow = keyboard` or a fixed monitor. |
| Bar and tray | i3bar, XEmbed tray | swaybar, **SNI-only tray** | nm-applet needs `--indicator`. parcellite (GtkStatusIcon) cannot show. ibus shows only with `XDG_CURRENT_DESKTOP=KDE` (`sway_ibus.sh`). **swaybar before 1.11 cannot open tray right-click menus** (no dbusmenu): left-click activates the app (flameshot starts a capture), but menus of nm-applet, blueman, kdeconnect, flameshot, ibus do not open. On sway < 1.11, use the apps' own windows or waybar for menus. |
| Launcher | rofi 1.7 (X11) | rofi ≥ 2.0 (Wayland backend) or rofi-wayland | X11 rofi under XWayland misplaces itself and grabs the keyboard unreliably. `window`/`windowcd` X modes → `sway_window_switcher.sh`. |
| Desktop widgets | conky (X11 own_window) | conky ≥ 1.19 with `out_to_wayland = true` (layer-shell) | Handled by a patched temporary copy (`sway_conky_monitor_display.sh`). |
| GTK theme, fonts, cursor | `~/.gtkrc-2.0`, Xresources, xsettingsd | gsettings (`sway_import_gsettings.sh`), `seat * xcursor_theme` | xsettingsd and Xresources still apply, but only to XWayland apps. |
| Window magnifier | magnus, xzoom | woomer (unofficial, built from source) | No packaged equivalent. |
| On-screen keyboard | Florence (XTEST) | wvkbd / squeekboard (virtual-keyboard protocol) | Florence typing never reaches native Wayland windows. |
| Key display | screenkey | showmethekey (reads libinput through a pkexec helper) | |
| Pointer warping on focus | xdotool mousemove | `mouse_warping container` or `seat - cursor set` | |

---

## 3. Input method (ibus / chewing)

- **XWayland apps:** ibus works as before, as long as `XMODIFIERS` (with the S) is set.
- **Native GTK/Qt apps:** these need the Wayland input-method path: the IM daemon speaks
  `zwp_input_method_v2` to sway, and apps speak `text-input-v3`. sway implements both.
  Candidate popups are positioned correctly only on **sway ≥ 1.10**.
- **ibus does not support this path.** Its Wayland front end implements only
  `input-method-v1` (Weston), which sway does not provide. *Correction after testing
  (test_v1): this report first said ibus ≥ 1.5.27 works here; switching to chewing in
  kitty failed.* On sway, ibus reaches:
  - XWayland apps, through `XMODIFIERS`
  - GTK/Qt apps, through the `GTK_IM_MODULE`/`QT_IM_MODULE=ibus` D-Bus modules
  - kitty, because `kitty_common.conf` now sets `linux_display_server x11`. kitty's GLFW
    talks to ibus directly on X11; on i3 this changes nothing.

  It cannot reach native `text-input-v3`-only apps: Chromium/Electron on the Wayland
  backend, foot. Those need fcitx5.
- The IM variables no longer depend on `~/.profile`. `sway_input_method.sh` writes them to
  `~/.config/environment.d/60-sway-input-method.conf`, which GDM imports for every session.
  test_v3 showed sway being started without `sway-session`, so the profile-only approach
  failed.
- Choose the framework with `set $default_input_method ibus|fcitx5`, or run
  `sway_input_method.sh use fcitx5`. fcitx5 is the recommended choice on sway: native
  Wayland input, and a tray icon swaybar can show.
- **fcitx5 + fcitx5-chewing** has the best wlroots support. If you switch:
  - swap the two lines in `sway_startup.config`
  - set `XMODIFIERS=@im=fcitx`
  - **do not** set `GTK_IM_MODULE` for native Wayland GTK apps (fcitx5's own guidance)
  - keep `QT_IM_MODULE=fcitx` only for Qt5
  - `i3_languagechanger.sh` (ibus engine cycling) then needs an fcitx5 equivalent:
    `fcitx5-remote -t`
- The `Shift+space` full-width notice and the `Ctrl+Mod1+space` engine switch are kept.

---

## 4. HiDPI / scaling

- sway supports per-output fractional scaling (`output <name> scale 1.25`). Native
  Wayland apps render sharply at any scale.
- XWayland apps are rendered at scale 1 and upscaled, so they are **blurry on fractional
  scales**. Keep integer scales on outputs where you use X-only apps, or move those apps
  to native builds (see 04).

---

## 5. Things that do not exist on sway at all (documented, not converted)

| Feature | Why | Workaround in this config |
| :-- | :-- | :-- |
| `title_window_icon` | i3-only feature | None (commented out). |
| `tiling_drag swap_modifier` | Not implemented in sway | Mark/swap bindings. |
| `open` (empty placeholder container) | Not implemented | `float_then_fulfill_workspace with_placeholder` degrades to without a placeholder. |
| `append_layout` / i3-resurrect layout restore | Not implemented | `sway_workspace_operator.sh` saves and relaunches programs per workspace; split geometry is not restored. |
| `restart` (re-exec keeping the layout) | Not needed | `reload`. |
| Primary output (`tray_output primary`, xrandr `--primary`) | Wayland has no such concept | `tray_output *`; the "primary" display action moves workspace 1 / focus. |
| `set_from_resource` | No X resource database | pywal template + `include`. |
| Global keylogging/hotkeys by apps (Discord push-to-talk, AutoKey, X-based remote control) | Wayland security model | Bind keys in sway and call the app's CLI, or keep the app focused. |
| Remote control of this machine (KDE Connect remote input, TeamViewer/AnyDesk host) | xdg-desktop-portal-wlr has no RemoteDesktop portal | wayvnc for VNC hosting; incoming remote input from KDE Connect is unavailable. |
| Window thumbnails in a switcher | X compositing API | Text-only switcher. |
| True output mirroring | Not in sway | wl-mirror (a window showing another output). |

---

## 6. kanshi: automatic display profiles (replaces `auto_in_office` / `auto_at_home`)

`~/.config/kanshi/config` example. Adapt names with `swaymsg -t get_outputs`. You can
match by `"Make Model Serial"` to tell monitors apart.

```
profile laptop {
    output eDP-1 enable mode 1920x1080 position 0,0 scale 1
}
profile office {
    output eDP-1    enable mode 1920x1080 position 0,1080
    output HDMI-A-1 enable mode 1920x1080 position 0,0
}
profile home {
    output eDP-1 disable
    output "Dell Inc. DELL U2720Q *" enable mode 3840x2160 scale 1.5 position 0,0
}
```

Then replace `exec $SWAY_SCRIPT/sway_display_operator.sh auto …` in
`sway_startup.config` with `exec kanshi`.
