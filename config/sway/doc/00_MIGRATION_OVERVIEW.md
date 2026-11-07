# 00 — i3 → sway Migration Overview

**Date:** 2026-11-07. **Source:** `config/i3` (current working tree). **Target:** `config/sway`.

**Status: migrated.** Tested on a ThinkPad E14 (Ubuntu 24.04.5, sway 1.9) over six test
rounds, followed by a final review. The process is described in [06](06_MIGRATION_PROCESS.md).

## Reports

| # | Report | Answers |
| :-- | :-- | :-- |
| 00 | this file | Summary, start-up checklist, consolidated list of what could not be converted |
| 01 | [Config conversion](01_CONFIG_CONVERSION.md) | How each i3 config file and line was converted |
| 02 | [Script porting](02_SCRIPT_PORTING.md) + [`migration/`](migration/) | Which scripts were ported, reused or added, subcommand by subcommand |
| 03 | [X11 → Wayland changes](03_X11_TO_WAYLAND_CHANGES.md) | What must change when moving from X11 to Wayland, and why |
| 04 | [XWayland app coverage](04_XWAYLAND_APP_COVERAGE.md) | How XWayland and native builds cover my application selection |
| 05 | [Packages & install](05_PACKAGES_AND_INSTALL.md) | Package mapping, `installation/install_sway.sh` |
| 06 | [Migration process](06_MIGRATION_PROCESS.md) | Steps, test rounds, lessons, how to maintain both configs |
| 07 | [i3 ↔ sway correspondence](07_I3_SWAY_CORRESPONDENCE.md) | Which application/script replaces which, and how each differs |

## Result in numbers

| Item | Count |
| :-- | --: |
| sway config lines (11 i3 files → 13 sway files) | 2,523 |
| Modes converted | 103 of 103 (1 binding into an undefined mode disabled, as in i3) |
| Bindings | 1,879, no duplicates (checked) |
| Scripts referenced by the i3 config | 49 |
| Shared i3 scripts audited and reused unchanged through `$I3_SCRIPT` | 22 |
| → ported to `$SWAY_SCRIPT/sway_*` (same CLI) | 41 files |
| New sway-only helper scripts | 5 |
| Static checker problems (undefined modes/vars, missing scripts, duplicates, unknown commands) | 0 |

## Start-up checklist

1. **Pop!_OS 22.04 is too old** (sway 1.7). Upgrade to 24.04, use Fedora, or build sway
   ≥ 1.9 from source.
2. **NVIDIA proprietary driver detected:** `nvidia-drm.modeset=1` is required.
   `sway-session` adds `--unsupported-gpu` automatically.
3. Run `installation/install_sway.sh`.
4. Log in with **"Sway (user session)"**. It loads `~/.profile`; fish never did.
5. Fix `$monitor1..5` from `swaymsg -t get_outputs`.
6. Validate with `sway -C -c ~/.config/sway/config`.
7. Fix the typo `XMODIFIER` → `XMODIFIERS` in `config/i3/share/default_profile`.

## Things I fixed or found along the way

| Finding | Where |
| :-- | :-- |
| sway expands variables line by line, so 103 `set $mode_*` labels were moved to `sway_mode_name.config`. Otherwise 20+ bindings would have pointed at mangled mode names (e.g. `$mode_gaps` + `_outer`). | 01 |
| `tiling_drag modifier titlebar` would have **disabled** dragging on sway. It is now `tiling_drag enable`. | 01 |
| `$mode_clink` is used but never defined (an existing i3 bug). Disabled in the sway copy. | 01 |
| `XMODIFIER` typo in `default_profile`: X11 apps never connected to ibus. | 03 §1.4 |
| `HDMI1_1912x960_60` was bound in i3 but never implemented. It works in the sway display operator. | 02 |
| The i3 gap/border operators could overwrite whole files when their target line was missing. The sway versions refuse. | 02 |
| **Review pass:** `i3_conky_valuechanger.sh` read its defaults from the i3 config. It is now ported as `sway_conky_valuechanger.sh`. | 02 |
| **Review pass:** without `inhibit_idle fullscreen`, swayidle would lock the screen during fullscreen video, because X11 players reset the X screensaver timer and swayidle ignores that. Rules added to `sway_window.config`. | 03 |
| **Review pass:** no `sway-portals.conf` meant screen sharing could pick the wrong portal backend. `share/sway-portals.conf` added; the installer links it. | 03, 05 |
| **Review pass:** packages started by the config but installed by no script: xsettingsd, nm-applet, xrdb (Fedora), fd/ripgrep/pdfgrep. Added to the installer. | 05 |
| **Review pass:** polkit agent path was Ubuntu-only. It now falls back to the Fedora path. ranger (`yf`, wallpaper), zathura (`Ctrl+c`) now prefer `wl-copy`/`swaymsg` and keep the X11 command as fallback for i3. | 01, 04 |

## What could NOT be fully converted (consolidated)

| # | Feature (i3/X11) | Status on sway | Reason / workaround |
| --: | :-- | :-- | :-- |
| 1 | `title_window_icon` (icons in titlebars) | ❌ | Not implemented in sway. |
| 2 | `tiling_drag swap_modifier` (Shift-drag swap) | ❌ | Not implemented. Use mark/swap bindings. |
| 3 | `i3-msg open` (empty placeholder) and `float_then_fulfill_workspace with_placeholder` | ❌ / ⚠️ | No `open` command. Floats without a placeholder. |
| 4 | i3-resurrect workspace layout restore | ⚠️ | No `append_layout`. Save/restore relaunches the programs onto their workspaces; splits and geometry are not restored. |
| 5 | rofi `windowcd` window thumbnails | ⚠️ | Text-only switcher (`sway_window_switcher.sh`). |
| 6 | picom blur, shadows, rounded corners, fading | ⚠️ | Opacity is native. The rest needs SwayFX (optional in the installer). No fading. |
| 7 | "Primary" output (`tray_output primary`, `xrandr --primary`) | ⚠️ | No such concept. `tray_output *`; "primary" moves workspace 1 / focus. |
| 8 | Output mirroring | ⚠️ | wl-mirror (a mirror window), not true mirroring. |
| 9 | Per-display software brightness (`xrandr --brightness`) | ⚠️ | ddcutil for external monitors; gammastep `-b` dims all outputs at once. |
| 10 | Screen magnifiers (magnus, xzoom) | ⚠️ | woomer (unofficial, built from source), otherwise a notification. |
| 11 | KDE Connect remote input (phone as touchpad/keyboard), picom colour-inverted pointer | ❌ | xdg-desktop-portal-wlr has no RemoteDesktop portal. The pointer-invert subcommands are stubs. |
| 12 | Being remote-controlled (TeamViewer/AnyDesk host) | ❌ | Same reason. wayvnc can serve VNC instead. |
| 13 | Florence on-screen keyboard | ❌ | XTEST typing doesn't reach Wayland windows. Use wvkbd/squeekboard. |
| 14 | Global hotkeys/key capture by apps (Discord push-to-talk, screenkey) | ⚠️ | Wayland isolation. showmethekey replaces screenkey; other apps only while focused. |
| 15 | imwheel per-button/per-app wheel speed | ⚠️ | Only a global `scroll_factor`. |
| 16 | Shift+click-and-hold in mouse mode | ⚠️ | Needs ydotool (ydotoold + uinput). Everything else in mouse mode is native. |
| 17 | Caps/NumLock "send key" in keyboard mode | ⚠️ | wtype may not toggle the lock state on every keyboard. |
| 18 | ibus on native Wayland apps | ⚠️ | ibus has no input-method-v2 support. Works for XWayland apps, GTK/Qt (IM modules) and kitty (forced to XWayland). Native text-input-v3-only apps (Chromium/Electron on Wayland, foot) need fcitx5 (sway ≥ 1.10). |
| 19 | conky on a chosen display | ⚠️ | Needs conky ≥ 1.19 built with Wayland. The output is chosen by briefly focusing it. |
| 20 | Gpick/Xmag/X-based pickers on all windows | ⚠️ | X clients only see XWayland windows. Replaced by the grim-based picker. |
| 21 | `restart` (in-place re-exec) | ✅ | Not needed: `reload` keeps windows and re-runs `exec_always`. |
| 22 | `set_from_resource` (Xresources colors) | ✅ | pywal template + `include` (full equivalent). |

## Fixes after the first test (`test_v1.md`)

| Reported | Cause | Fix |
| :-- | :-- | :-- |
| showmethekey: `Dependency "xkbregistry" not found` | Ubuntu splits it into `libxkbregistry-dev` | Added to the installer; a failed `meson setup` no longer runs ninja. |
| woomer: `failed to find branch freeze-feat-andreas` | Upstream woomer depends on a wayshot branch that was deleted | The installer clones woomer and pins the commit from its `Cargo.lock` (still exists) by `rev`, then `cargo install --path .`. Also installs raylib's build deps (cmake, libclang, GL/EGL). Dependency resolution was tested; the full build was not run here. |
| autotiling does not start; swaybar "error from status command" | pip `--user` tools are in `~/.local/bin`, missing from sway's PATH when `~/.profile` was not loaded. Also, the installer called `/usr/bin/python`, which Ubuntu 24.04 lacks. | `sway_run.sh` (PATH fix) for bumblebee-status, autotiling, flashfocus. `sway-session` now always adds these PATH entries. `sway_session_check.sh` warns at login. Installer uses `python3 -m pip` and installs bumblebee-status too. |
| rofi: `Control+c is already bound` | rofi 2.0 added `kb-secondary-copy = Control+c` (checked in rofi's `keyb.c`) | `config/sway/bin/rofi` wrapper adds overrides on top of the shared config. |
| rofi: Super+d `mode windowcd is not found` | `modi` in the shared config lists the X11-only `windowcd` | Same wrapper drops it. dunst's `dmenu` now calls `rofi` by name, not `/usr/bin/rofi` (the old X11 build). |
| ibus: cannot switch to chewing | ibus has no input-method-v2 support, so native Wayland kitty never got the IM. Report 03 was wrong about ibus ≥ 1.5.27. | kitty: `linux_display_server x11` (XWayland, as on i3). IM variables added to the D-Bus activation environment. Report 03 §3 corrected. For native Wayland apps: fcitx5. |
| kitty image preview (ueberzug), noted for later | ueberzug draws X11 child windows | Not addressed. With kitty now on XWayland, ueberzug may work again; untested. |

## Fixes after the second test (`test_v2.md`)

| Reported | Cause | Fix |
| :-- | :-- | :-- |
| woomer: `feature edition2024 is required` (cargo 1.75) | woomer's locked dependencies need cargo ≥ 1.85, and `cargo install` without `--locked` re-resolved them anyway | Cargo.toml and Cargo.lock are both pinned to the wayshot commit, and the build uses `--locked` (resolution verified). A cargo older than 1.85 gets a private rustup toolchain in the build directory; `~/.cargo` is untouched. woomer goes to `~/.local/bin`. |
| ibus still not working, no tray icon | ibus-ui-gtk3 only uses a StatusNotifierItem (what swaybar shows) when `XDG_CURRENT_DESKTOP=KDE`. Its native Wayland candidate window gets tiled and focused by sway. | `sway_ibus.sh` starts ibus-daemon with `XDG_CURRENT_DESKTOP=KDE GDK_BACKEND=x11` (only for ibus). Floating/no_focus rules for ibus windows. `sway_session_check.sh` reports missing IM variables. |
| flameshot tray not clickable, PrtScn does nothing | The sway config never started flameshot, and PrtScn used grim+slurp, whose failures were silent. swaybar < 1.11 cannot show tray right-click menus (all apps). | `exec flameshot` plus flameshot's documented sway window rule. PrtScn runs `flameshot gui -p ~/Pictures` as on i3, falling back to grim+slurp. Errors are notified and logged to `$XDG_RUNTIME_DIR/sway_screenshot.log`. Installer sets `useGrimAdapter=true`. |
| `Mod4+plus` must be `Mod4+equal` | i3 binds the key; sway matches the produced keysym (`plus` needs Shift, and `Shift+plus` never matches because Shift is consumed) | 20 `plus` bindings → `equal`, `Shift+plus` → `Shift+equal`. No other shifted keysyms are bound with modifiers. |
| kitty/ranger image preview (ueberzug) | ueberzug is X11-only | `ueberzugpp` (installer group, OBS repo) + `~/.config/sway/bin/ueberzug`, which redirects ranger's `ueberzug layer` to `ueberzugpp layer --output wayland`. |
| rofi still `Control+c is already bound` | The wrapper decided by `rofi -v`; a git build prints `git describe` (can be `1.7.9-…`), so it passed through | Detects support by the `kb-secondary-copy` string in the rofi binary. Session check reports whether `rofi` resolves to the wrapper. |

## Fixes after the third test (`test/test_v3.md`)

`test/sway_session_check.log` showed the common cause: sway was **not** started by
`sway-session`, so `~/.profile` was not loaded. All four IM variables were missing, and
`~/.config/sway/bin` (the rofi wrapper) was not on PATH. `test/sway_screenshot.log` shows
4 × `flameshot gui` returning success with no overlay.

| Reported | Fix |
| :-- | :-- |
| rofi `Control+c is already bound` | As requested, `Control+c` is removed from `kb-cancel` in all shared `.rasi` files. `windowcd` is removed from `modi` too (i3's `-show windowcd` still works; rofi adds the shown mode). The rofi wrapper is deleted. |
| ibus/chewing not working, no tray | The IM variables now live in `~/.config/environment.d/60-sway-input-method.conf` (written by `sway_input_method.sh`, the installer and the login check). The systemd user manager reads it and GDM passes it to every session, whichever login entry is chosen. `sway-session` reads the same file. `sway_ibus.sh` restarts an ibus-daemon that lacks the KDE tray mode. **Alternative:** `sway_input_method.sh use fcitx5` (see below). |
| flameshot overlay never appears; PrtScn | PrtScn now defaults to grim + slurp (dimmed selection like flameshot) + satty/swappy editor: `set $default_screenshot_tool grim`. `flameshot` stays selectable; its daemon then starts with `QT_QPA_PLATFORM=wayland`. |

### Wayland alternatives if ibus / flameshot still fail

| Instead of | Use on sway | Why |
| :-- | :-- | :-- |
| ibus + ibus-chewing | **fcitx5 + fcitx5-chewing** (`sway_input_method.sh use fcitx5`, re-login) | Implements input-method-v2, so native Wayland apps work without any variables. Its tray icon is a StatusNotifierItem (swaybar shows it). It also serves kitty through its ibus-compatible D-Bus front end (`GLFW_IM_MODULE=ibus`). Candidate popups in native Wayland apps need sway ≥ 1.10; XWayland apps and kitty work on 1.9. |
| flameshot | **grim + slurp + satty** (or swappy) | Native wlroots screencopy, no portal involved. satty is a flameshot-like annotation editor (not in Ubuntu 24.04: `cargo install satty`, or Fedora/Arch packages). swappy is installed already. |
| flameshot tray | none needed | swaybar < 1.11 cannot open tray menus anyway. PrtScn, Mod4+Print, Mod4+Shift+Print and the screenshot mode cover the flameshot actions. |

## Fixes after the fourth test (`test/test_v4.md`)

| Reported | Cause | Fix |
| :-- | :-- | :-- |
| woomer: raylib-sys `could not find glfw3 (requested version 3.4)` | raylib is built against an external GLFW ≥ 3.4. Ubuntu 24.04 ships 3.3.10. | The installer builds GLFW 3.4 (Wayland + X11, shared) into `/usr/local/lib/<triplet>` when `pkg-config` reports < 3.4. Fedora 40+ uses `glfw-devel`. The `core2` "yanked" warning is harmless. |
| `grim and slurp are required` | grim/slurp were not installed on the test machine. All 105 apt names in the installer exist on noble (checked), so the Wayland-tools group was skipped or apt failed. | `pkg` retries package by package when a bulk install fails, and lists failures. The installer ends with a check of every command the config uses. The notification now names what is missing and how to install it. |
| fcitx5: all IM variables `<unset>` although the environment.d file exists | GDM did not import `~/.config/environment.d` into the sway session. sway was started by the stock "Sway" entry (no `sway-session`). | (1) Installer Section 3 points the stock "Sway" entry at `sway-session` too (dpkg-divert on apt), so both login entries load the environment. (2) `sway_run.sh` reads the IM file, and every terminal binding (23) and rofi binding goes through it, so apps started from them get the variables even then. |

## Fixes after the fifth test (`test/test_v5.md`)

| Reported | Cause | Fix |
| :-- | :-- | :-- |
| woomer: `rust-lld: unable to find library -lglfw`, `-lgbm` | rust-lld only searches the `-L` paths it is given, and GLFW 3.4 is in `/usr/local/lib/<triplet>`. `libgbm-dev` was not installed. | `RUSTFLAGS="-L /usr/local/lib/<triplet> -C link-arg=-Wl,-rpath,…"`, plus `libgbm-dev` / `mesa-libgbm-devel`. |
| fcitx5 still not working (no logs) | Not determined. Two causes found in the code: (1) the us + chewing profile was only written when no profile existed; a keyboard-only profile created by fcitx5's first run left nothing to switch to. (2) A stale ibus address file in `~/.config/ibus/bus` could point kitty at a dead socket. | (1) The profile is rewritten (with a backup) whenever chewing is missing, and a running fcitx5 without chewing is restarted. (2) The address files are removed before fcitx5 starts. fcitx5 output goes to `$XDG_RUNTIME_DIR/fcitx5.log`. New `sway_input_method.sh doctor` writes `~/sway_im_doctor.txt`. Login check reports a missing `fcitx5-chewing` or ibus front end. |

## Fixes after the sixth test (`test/sway_im_doctor.txt`)

fcitx5 works for typing. `fcitx5-diagnose` shows kitty connected through `wayland_v2`. The
language switcher did nothing, for these reasons:

- `$default_input_method` still said `ibus`, so Ctrl+Alt+space ran the ibus switcher
  (`i3_languagechanger.sh`).
- ibus-daemon was running next to the manually started fcitx5.
- All session variables were still the ibus ones (`XMODIFIERS=@im=ibus`, …).

| Fix | Where |
| :-- | :-- |
| `toggle` follows the running daemon: fcitx5 → `fcitx5-remote -t` with a notification naming the new input method, ibus → `i3_languagechanger.sh`. It reports a failure when fcitx5 does not answer. | `sway_input_method.sh` |
| `$default_input_method` is now `fcitx5` | `config` |
| `start` rewrites the environment file when it does not match `$default_input_method`, and asks for one re-login | `sway_input_method.sh` |
| When ibus-daemon was running next to fcitx5, ibus is stopped and fcitx5 restarted, so kitty's ibus address file points at fcitx5 again | `sway_input_method.sh` |

## Final review (after test v6)

- The static checker passes: 2,535 lines, 188 variables, 103 modes, 1,879 bindings, no
  undefined variables or modes, no missing scripts, no duplicate bindings. All scripts
  pass `bash -n` / `py_compile`.
- New checks in the final pass:
  - sway variables silently mangling shell variables (none found)
  - `;` and `,` inside `exec` commands. Found the 8 mouse-mode scroll-repeat bindings
    (`exec for …; do …; done`) split by sway; now quoted.
- Every script path referenced from the config or the scripts exists and is executable.

## Verification status

- Tested on real hardware in six rounds; every reported issue is fixed (tables above).
- Still to watch:
  - `woomer`: the last build attempt failed at linking; the fix (GLFW libdir, rpath,
    libgbm) has not been confirmed by a rebuild yet
  - Tray menus: only with sway ≥ 1.11
  - Candidate popups of fcitx5 inside native Wayland apps: only with sway ≥ 1.10
