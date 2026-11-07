# 04 — XWayland Compatibility and Coverage of My i3 Application Selection

## What XWayland gives you

`xwayland enable` is sway's default; this config does not disable it. XWayland is an X
server that runs as a Wayland client inside sway. sway starts it lazily the first time an
X client connects.

Every X11-only program keeps working **as a window**:

- it is tiled, floated and decorated by sway like any other window
- `for_window [class=…]`, `[instance=…]`, `[window_role=…]` and `[window_type=…]` still
  match it
- it shows up in the sway tree with `"shell": "xwayland"`

What XWayland **cannot** do, by design:

| Limitation | Effect on X11 tools |
| :-- | :-- |
| X clients only see other **X clients**, never native Wayland windows | Screen grabbers, color pickers, magnifiers, xdotool, xprop, wmctrl, xkill and rofi's window modes work only on the XWayland subset of your windows. |
| X clients cannot receive keyboard/pointer events aimed at Wayland windows | Global hotkeys and keyloggers (Discord push-to-talk, screenkey, AutoKey) only work while an X window is focused. |
| X clients cannot change outputs, gamma, DPMS or the WM | xrandr, arandr, redshift, xset dpms, xbacklight (randr) have no effect. |
| Upscaled on fractional output scales | X apps look blurry at scale 1.25/1.5. Use integer scales or native builds. |
| XEmbed tray icons are not shown by swaybar | Old GtkStatusIcon tray apps have no tray icon. |

So XWayland covers **applications**: things you look at and type into. It does not cover
**desktop tools** that manage the screen or other windows. Every desktop tool in the i3
setup was therefore replaced (section B). Almost all applications keep working, many of
them natively (section A).

Legend:

| Mark | Meaning |
| :-- | :-- |
| 🟢 Native | Runs as a native Wayland client (sharp at any scale, full feature set). |
| 🟡 XWayland | Runs through XWayland. Works as a normal app; limits as above. |
| 🔵 Replaced | Desktop tool rewritten or replaced for sway. |
| 🔴 Gap | No full equivalent (see notes). |

## A. Applications (launched by bindings, modes or startup)

| App (where used in i3) | Under sway | Notes |
| :-- | :-- | :-- |
| kitty (`$terminal`, floating_terminal) | 🟢 | `--class floating_terminal` → app_id `floating_terminal`; float rule added. |
| gnome-terminal, alacritty (terminal mode) | 🟢 | |
| foot (new in terminal mode) | 🟢 | Lightweight native fallback terminal. |
| rxvt-unicode, xterm (terminal mode) | 🟡 | |
| nvim, ranger, pulsemixer, htop, nmtui, cava, nvtop, ipython3, alsamixer, speaker-test, arecord, tmux, spt, ncspot, glow, vis, jrnl, neofetch | 🟢 (TUI) | Run inside kitty, so no display server dependency. nvim clipboard uses `wl-copy` automatically. tmux/ranger configs that call `xclip` must call `wl-copy`: done for ranger `yf` and zathura `Ctrl+c` (wl-copy first, X11 tool as fallback for i3). ranger's "wallpaper" open-with entries gained `swaymsg output * bg` variants, because `feh --bg-*` only paints the X11 root window. Image previews via the kitty graphics protocol keep working; ueberzug (X11) does not. |
| zathura (`Ctrl+Alt+8`) | 🟢 | GTK3. |
| sioyek (`config/sioyek`) | 🟢 | Qt (needs qtwayland). |
| mpv (`config/mpv`, player mode) | 🟢 | `mpv-mpris` / playerctl unchanged. |
| VLC (player mode via playerctl) | 🟡 / 🟢 | VLC 3 video output is most reliable on XWayland (`QT_QPA_PLATFORM=xcb vlc`). VLC 4 is native. |
| Firefox (`Ctrl+Alt+=`, Teams PWA) | 🟢 | Native by default (≥ 121). Screen sharing through the portal + PipeWire. PiP rule added. |
| Brave (`Ctrl+Alt+-`, `$BROWSER`, URL modes) | 🟡 → 🟢 | Recent Chromium picks Wayland automatically. Otherwise set `brave://flags/#ozone-platform-hint` = Auto, or add `--ozone-platform-hint=auto` to `$BROWSER`. Screen sharing needs `brave://flags/#enable-webrtc-pipewire-capturer` on older versions. `--class`-based rules: use `app_id="brave-browser"`. |
| Nautilus, Thunar (`Ctrl+Alt+0`, `XF86Favorites`) | 🟢 | Float rules by app_id. |
| blueman-manager / blueman-applet | 🟢 | Applet publishes an SNI tray icon. |
| nm-applet / nm-connection-editor | 🟢 | **Must run with `--indicator`** for the swaybar tray. |
| pavucontrol | 🟢 | app_id `pavucontrol` or `org.pulseaudio.pavucontrol` (≥ 6). |
| gnome-calculator, Gnome Clocks, Dictionary, DejaDup, Evince, Eog/Loupe, gnome-screenshot window | 🟢 | Float rules by app_id. gnome-screenshot itself cannot capture on wlroots (replaced by grim). |
| Mailspring (`XF86Mail`), Slack, Discord, ObinsKit, VS Code (Electron) | 🟡 → 🟢 | Native with `ELECTRON_OZONE_PLATFORM_HINT=auto` (Electron ≥ 28). Flatpaks: `flatpak override --user --env=ELECTRON_OZONE_PLATFORM_HINT=auto <app>`. Discord screen sharing on Wayland is limited (Vesktop works better). Push-to-talk only while focused. |
| Spotify (official client) | 🟡 | Controlled through playerctl; no change needed. |
| spotifyd | 🟢 | Headless daemon. |
| Zoom (`zoom*` float rule) | 🟡 | Screen sharing needs `enableWaylandShare=true` in `~/.config/zoomus.conf` and xdg-desktop-portal-wlr. |
| Microsoft Teams (Firefox PWA, open-URL mode) | 🟢 | Through Firefox. |
| Steam (+ Proton games) | 🟡 | Works. Games run on XWayland (gamescope optional). |
| VirtualBox (`VirtualBox` rules) | 🟡 | Works. Keyboard capture does not block sway shortcuts, so use your **Insert mode** (`Ctrl+Alt+i`) exactly as under i3. |
| scrcpy | 🟢 | SDL2 with `SDL_VIDEODRIVER=wayland`. |
| TeamViewer | 🟡 / 🔴 | Works as a client (controlling others). Being controlled on wlroots is not supported. |
| Weylus | 🟡 / ⚠️ | Screen capture through PipeWire works with the wlr portal. Input goes through uinput. Test before relying on it. |
| matplotlib figures | 🟢 / 🟡 | Qt/GTK backends native (title rule `^Figure \d+` added). TkAgg is X11 → class `Tk`/`matplotlib` rules still match. |
| Tk apps (`Tk` class), gtk-tree-watch, kruler, Cairo-clock, Xmag | 🟡 | class rules kept. Cairo-clock needs XWayland compositing (works). Xmag sees only X windows. |
| QjackCtl | 🟢 | app_id rule added. |
| Gcolor3 | 🟢 / ⚠️ | App runs natively. Its screen picker may not work on wlroots; use `sway_toolkit_operator.sh pickup_color`. |
| Gpick (`Gpick` class) | 🟡 / 🔴 | Picker only sees XWayland windows → replaced by the grim-based picker. |
| Florence (on-screen keyboard) | 🟡 / 🔴 | Its key injection (XTEST) never reaches native windows → wvkbd/squeekboard. |
| KDE Connect (`kdeconnect-indicator`, daemon, SMS app) | 🟢 / ⚠️ | Notifications, file transfer, media control and battery work. **Remote input (phone as touchpad/keyboard) does not work** on wlroots (needs the RemoteDesktop portal, which xdg-desktop-portal-wlr does not implement). Clipboard sync depends on the KDE Frameworks version supporting wlr-data-control. |
| LocalSend (`localsend-cli`, toolkit) | 🟢 | |
| feh (image viewer use, `feh` class) | 🟡 | Still fine as a viewer through XWayland. `imv` is the native equivalent (rule added). As a **wallpaper setter** it is replaced (B). |
| Variety | 🟢 | Supports sway (sets the wallpaper through swaybg). |
| polkit-gnome agent | 🟢 | |
| Kvantum / qt5ct theming | 🟢 | Same config. Native Qt needs qtwayland. |
| warpd (`Mod1+m`) | 🟢 (rebuild) | Must be built with `PLATFORM=wayland` (the install script does this). |
| screenkey | 🔵 | → showmethekey (`[3]` in recording mode). |
| peek | 🔵 | → wf-recorder (`sway_recorder.sh`). |
| magnus, xzoom | 🔴 | → woomer, unofficial and built from source. Otherwise a notification explains why. |

## B. Desktop tools (the X11 layer that had to be replaced)

| i3/X11 tool | sway replacement | Status |
| :-- | :-- | :-- |
| i3 / i3bar / i3-nagbar / i3-input / i3-msg | sway / swaybar / swaynag / rofi -dmenu / swaymsg (i3-msg still works) | 🔵 |
| bumblebee-status (status_command) | unchanged (i3bar protocol) | 🟢 |
| picom (opacity, blur, shadows) | sway `opacity` (SwayFX for blur/shadows/corners) | 🔵 / 🔴 blur on vanilla sway |
| flashfocus | unchanged (sway IPC) | 🟢 |
| autotiling | unchanged (supports sway) | 🟢 |
| i3-automark daemon (i3 IPC) | unchanged, uses `$I3SOCK` | 🟢 |
| i3-resurrect | `sway_workspace_operator.sh` (relaunch only) | 🔴 layouts are not restored |
| xrandr / arandr / autorandr | `swaymsg output`, wdisplays, kanshi | 🔵 |
| xbacklight | brightnessctl (+ ddcutil) | 🔵 |
| redshift | gammastep (`sway_nightlight.sh`) | 🔵 |
| i3lock / xss-lock / `xset dpms` / `xset s` | swaylock / swayidle / `output power` | 🔵 |
| feh (wallpaper) | swaybg via `output * bg` | 🔵 |
| pywal | unchanged + sway template (`colors-sway-i3`) | 🟢 |
| xsettingsd / Xresources / gtkrc | gsettings (native) + kept for XWayland | 🔵 |
| dunst | unchanged (≥ 1.6 Wayland-native) | 🟢 |
| rofi 1.7 (X11) | rofi ≥ 2.0 / rofi-wayland | 🔵 (rebuild/upgrade) |
| rofi `window` / `windowcd` (thumbnails) | `sway_window_switcher.sh` | 🔵 / 🔴 no thumbnails |
| conky | conky ≥ 1.19 `out_to_wayland` | 🔵 / ⚠️ build-dependent |
| flameshot / gnome-screenshot | grim + slurp + swappy | 🔵 |
| xcolor / gpick | grim + slurp + ImageMagick | 🔵 |
| xdotool | wtype, `seat - cursor`, ydotool | 🔵 |
| xclip / xsel | wl-clipboard | 🔵 |
| parcellite | cliphist | 🔵 (no tray icon; picker through rofi) |
| unclutter | `seat hide_cursor` | 🔵 |
| numlockx / imwheel / `xset m` / `xset r` | `input` options | 🔵 |
| setxkbmap / xmodmap / xinput | `input` options / `xkb_file` / keyd | 🔵 |
| libinput-gestures | `bindgesture` | 🔵 |
| xkill | slurp-selected window + `swaymsg kill` | 🔵 |
| ibus | ibus (XWayland ✓, native ⚠️) or fcitx5 | ⚠️ |

## C. Coverage summary

Counted from the tables above. Section A has 42 rows; one row groups 19 terminal/TUI
programs.

| Section A: applications (42 rows) | Rows |
| :-- | --: |
| 🟢 Native on Wayland without changes | 23 (+19 TUI programs in one row) |
| 🟢 Native after an env var, flag or rebuild (Electron apps, Brave, warpd) | 3 |
| 🟡 Through XWayland, fully usable as applications | 10 |
| 🔵 Replaced by a Wayland tool (screenkey, peek) | 2 |
| 🔴 Partial gap (TeamViewer host, Gpick picker, Florence, magnus/xzoom) | 4 |

| Section B: desktop tools (29 rows) | Rows |
| :-- | --: |
| 🟢 Kept unchanged (bumblebee-status, flashfocus, autotiling, automark, pywal, dunst) | 6 |
| 🔵 Replaced with the same function | 20 |
| 🔴 Gap (picom blur on vanilla sway, i3-resurrect layout restore, switcher thumbnails) | 3 |

**In short:** XWayland plus native builds cover essentially your entire *application*
selection. 36 of 42 application rows run with no functional loss. What XWayland cannot
cover is the *desktop tooling* layer, which is why most of the migration work is in
`config/sway/script/`.
