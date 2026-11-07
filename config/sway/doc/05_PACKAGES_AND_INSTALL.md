# 05 — Packages and Installation

Script: [`installation/install_sway.sh`](../../../installation/install_sway.sh)

- Interactive, in the same style as the existing i3 install scripts: a `desc_*` and
  `install_*` function per group, and a `no` / `one-by-one` / `all` menu.
- Works with **apt** (Ubuntu/Pop!_OS 24.04+) and **dnf** (Fedora 40+). The `pkg` helper
  takes `apt names -- dnf names`.
- Installs only what sway needs **on top of** the i3 environment. Run the i3 script first
  for the shared tools: kitty, fish, tmux, pywal, bumblebee-status, dunst config, rofi
  themes, sioyek, kdeconnect, variety. (fd/ripgrep/pdfgrep are **not** in the i3 scripts;
  the sway script installs them for omnisearch.)
- If a bulk install fails (one bad or conflicting name makes apt/dnf install nothing), `pkg`
  retries one package at a time. The script ends with a list of failed packages and of
  commands the config needs that are still missing.
- Stops with a warning on 22.04 (sway 1.7 is too old; see 03 §1.1).
- Section 3 links `~/.config/sway`, installs the pywal template, generates the first
  palette, links `share/sway-portals.conf` to `~/.config/xdg-desktop-portal/`, writes the input-method
  environment file, points the stock "Sway" login entry at `sway-session` (dpkg-divert on apt),
  and installs `/usr/local/bin/sway-session` and the "Sway (user session)" login
  entry.

## Package groups

| Group | apt (Ubuntu 24.04) | dnf (Fedora) | Replaces (i3/X11) |
| :-- | :-- | :-- | :-- |
| **Sway core** | sway swaybg swaylock swayidle xwayland i3-wm jq python3-i3ipc | sway swaybg swaylock swayidle xorg-x11-server-Xwayland i3 jq python3-i3ipc | i3, i3bar, i3-nagbar, i3lock, xss-lock, feh (wallpaper). `i3-wm` stays for the `i3-msg` used by shared scripts. |
| **Session** | xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk pipewire wireplumber policykit-1-gnome gnome-keyring libnotify-bin qtwayland5 qt6-wayland xsettingsd network-manager-gnome blueman x11-xserver-utils libglib2.0-bin | xdg-desktop-portal(-wlr,-gtk) pipewire wireplumber polkit-gnome gnome-keyring libnotify qt5-qtwayland qt6-qtwayland xsettingsd network-manager-applet blueman xrdb glib2 | X11 had no portals. Needed for screen sharing and file pickers, and for native Qt apps. The rest are started by `sway_startup.config` (xsettingsd, nm-applet, blueman-applet, gsettings import, xrdb); no installer provided them before. |
| **Wayland tools** | wl-clipboard grim slurp swappy wf-recorder wdisplays kanshi wlr-randr brightnessctl ddcutil gammastep wtype ydotool imagemagick tesseract-ocr(-eng,-chi-tra) zbar-tools foot wl-mirror libxkbcommon-tools bc psmisc translate-shell + **cliphist** (package or `go install`) | same names (ImageMagick, tesseract-langpack-*, zbar, libxkbcommon-utils) + cliphist | xclip/xsel, parcellite, flameshot, gnome-screenshot, peek, arandr/xrandr/autorandr, xbacklight, redshift, xdotool, xcolor/gpick, xkbcomp |
| **Desktop** | dunst conky-all fd-find ripgrep pdfgrep sqlite3 poppler-utils + **rofi ≥ 2.0 built from source** (24.04 ships X11-only 1.7.5) + `python3 -m pip`: autotiling flashfocus i3ipc bumblebee-status | dunst conky fd-find ripgrep pdfgrep sqlite poppler-utils rofi-wayland + pip | rofi 1.7 (X11), conky (X11 own_window) |
| **Input method** | fcitx5 fcitx5-chewing fcitx5-config-qt fcitx5-frontend-gtk3/gtk4/qt5 | fcitx5 fcitx5-chewing fcitx5-configtool fcitx5-gtk fcitx5-qt | Optional alternative to ibus (better Wayland support) |
| **Source builds** | warpd (`PLATFORM=wayland`), showmethekey (+ `libxkbregistry-dev`), woomer (GLFW ≥ 3.4 built into `/usr/local` on Ubuntu 24.04, which ships 3.3; cargo ≥ 1.85 — a private rustup toolchain in the build dir if the system cargo is older; libwayshot pinned by rev in Cargo.toml + Cargo.lock, built `--locked`; needs cmake, libclang, GL/EGL dev) | same (xkbregistry is in libxkbcommon-devel) | warpd X11 build, screenkey, magnus/xzoom |
| **ueberzugpp** | OBS repo `home:justkidding` (`xUbuntu_<ver>`) | `dnf install ueberzugpp`, else OBS `Fedora_<ver>` | ueberzug (ranger image previews) |
| **SwayFX** (optional, asked separately) | not packaged → build | COPR `swayfx/swayfx` | picom blur, shadows, rounded corners |

## Group memberships and services set up by the script

| Item | Why |
| :-- | :-- |
| `video` group | brightnessctl writes `/sys/class/backlight` |
| `i2c` group | ddcutil brightness for external monitors (also load `i2c-dev`) |
| `ydotool.service` (user) | ydotoold for held modifiers in mouse mode (`/dev/uinput`) |
| `input` group | **No longer needed:** libinput-gestures is replaced by `bindgesture` |

## No longer needed under sway

These can stay installed for i3, but sway does not use them:

picom, feh (as wallpaper setter), xbacklight, redshift, arandr, i3lock, xss-lock,
unclutter, imwheel, numlockx, xdotool, xclip, xsel, wmctrl, xprop, flameshot,
gnome-screenshot, peek, screenkey, xzoom, magnus, parcellite, libinput-gestures,
i3-resurrect, i3-workspace-swap.

`x11-xserver-utils` is only needed for `xrdb` (Xresources for XWayland apps).

## After installing

1. Log out and back in (group changes).
2. Choose **Sway (user session)** at login, or run `sway-session` from a TTY.
3. `swaymsg -t get_outputs`, then set `$monitor1..5` in `~/.config/sway/config`.
4. `sway -C -c ~/.config/sway/config` validates the config. This is the one check that
   could not be run during the migration.
5. NVIDIA: `sudo kernelstub -a nvidia-drm.modeset=1` (Pop!_OS), then reboot.
6. Optional: kanshi profiles (03 §6), choose ibus or fcitx5 (03 §3).
