# 06 — Migration Process (i3 → sway)

How the i3 configuration in `config/i3` became the sway configuration in `config/sway`,
how it was tested, and how to keep the two in step from now on.

**Status:** migrated. Tested on a ThinkPad E14 with Ubuntu 24.04.5 LTS and sway 1.9, over
six test rounds (`test/test_v1.md` … `test/sway_im_doctor.txt`). No open issues.

---

## 1. Steps

### Step 1: inventory

- Read every file in `config/i3` (11 config files, 103 modes, ~1,860 bindings) and every
  script the config calls (49).
- Classified each X11 dependency: xrandr, xdotool, xprop, xclip, feh, picom, i3lock,
  xss-lock, Xresources, ibus over XIM, and so on.
- Checked sway's own behavior in its source (variable expansion, `include`, `tiling_drag`,
  `exec` flags, IPC sockets), not in i3 documentation.

### Step 2: mechanical config conversion

- Every i3 config file was converted to a `sway_*.config` with the same structure. i3-only
  syntax was rewritten or dropped. Report: [01](01_CONFIG_CONVERSION.md).
- Settings that X11 tools made at startup became declarative sway config in a new
  `sway_input_output.config`: keyboard, pointer, cursor hiding, gestures, lid switch.
- All `set $mode_*` labels were moved to `sway_mode_name.config`, which is included early.
  sway expands variables line by line, using the longest variable defined so far. Without
  the move, `$mode_gaps_outer` would have been read as `$mode_gaps` + `_outer`.
- Colors: `set_from_resource` (Xresources) → pywal user template
  `share/wal_templates/colors-sway-i3` plus `include`.

### Step 3: scripts

- 41 scripts that depended on X11 or edited the i3 config were ported to `sway_*`, keeping
  their subcommands so every binding maps one to one.
- 16 scripts that only use i3 IPC are reused unchanged (sway exports `I3SOCK`).
- Features with no Wayland equivalent became notification stubs, so no binding fails
  silently.
- Details: [02](02_SCRIPT_PORTING.md), [`migration/`](migration/),
  [07](07_I3_SWAY_CORRESPONDENCE.md).

### Step 4: Wayland session and applications

- Replacement applications: [07 §1](07_I3_SWAY_CORRESPONDENCE.md).
- Session plumbing that X11 did not need: portals, PipeWire, D-Bus activation environment,
  `sway-session`. Why each is needed: [03](03_X11_TO_WAYLAND_CHANGES.md).
- XWayland coverage of the application selection: [04](04_XWAYLAND_APP_COVERAGE.md).

### Step 5: installer

- `installation/install_sway.sh`: apt (Ubuntu 24.04+) and dnf (Fedora 40+), the same
  menu style as the i3 installers, source builds where no package exists.
- Section 3 links the config and installs the session launcher. Report:
  [05](05_PACKAGES_AND_INSTALL.md).

### Step 6: static verification

- A checker replays sway's include and variable rules over the whole config. It looks for:
  - undefined variables and modes, variables mangled by longer names
  - missing scripts, duplicate bindings, unknown commands
  - `;` or `,` inside `exec` commands that sway would split
- `bash -n` / `py_compile` on all scripts. Mock sway trees for the scripts that parse
  `get_tree`.
- Final state: 2,535 lines, 188 variables, 103 modes, 1,879 bindings, 0 problems.

### Step 7: test rounds on real hardware

| Round | Main findings | Main fixes |
| :-- | :-- | :-- |
| v1 | showmethekey/woomer builds, autotiling and bumblebee not starting, rofi `Control+c` / `windowcd`, ibus | `libxkbregistry-dev`; `sway_run.sh` (pip `--user` PATH); `python3 -m pip`; kitty → X11 for ibus |
| v2 | woomer needs cargo ≥ 1.85, ibus tray, flameshot, `Mod4+plus`, ueberzug, rofi again | Private rustup toolchain; ibus in KDE tray mode; `plus` → `equal` (sway matches keysyms, i3 matched keys); ueberzugpp |
| v3 | sway started without `sway-session`, so no IM variables; flameshot overlay never shown | environment.d file; ibus ↔ fcitx5 switch (`sway_input_method.sh`); grim + slurp default for PrtScn; `Control+c` removed from the rofi configs |
| v4 | GLFW 3.4 for woomer, grim/slurp missing, variables still unset | GLFW 3.4 build; per-package install retry and final command check; stock "Sway" login entry → `sway-session`; terminal and rofi bindings through `sway_run.sh` |
| v5 | woomer link errors, fcitx5 unclear | `-L`/rpath for GLFW, `libgbm-dev`; chewing profile repair; `doctor` report |
| v6 | fcitx5 works, but Ctrl+Alt+space did nothing | Switcher follows the running daemon; fcitx5 is the default framework |
| final review | 8 scroll-repeat bindings in mouse mode split at `;` | Shell loops quoted |

The full tables are in [00](00_MIGRATION_OVERVIEW.md) ("Fixes after …").

---

## 2. Lessons that apply to any i3 → sway migration

1. **Variables:** sway expands variables per line, and the longest variable *defined so
   far* wins. Define every variable before any line that uses it, and avoid names that
   are prefixes of other names.
2. **Keysyms:** i3 binds the key that produces a keysym; sway matches the keysym produced.
   `Mod4+plus` must be `Mod4+equal`, and `Shift+plus` never fires.
3. **`exec` and separators:** `;` and `,` split sway commands even inside `exec`. Quote
   shell code: `exec "for …; do …; done"`.
4. **Session environment:** a display-manager entry that runs plain `sway` skips
   `~/.profile` (and fish never reads it). Start sway through a launcher, and do not rely
   on the session environment for app launches.
5. **Input methods:** ibus has no input-method-v2 and its tray is XEmbed. fcitx5 is the
   practical choice on sway.
6. **Tray:** swaybar only shows StatusNotifierItem icons, and opens their menus only from
   sway 1.11.
7. **Distro age:** Ubuntu 24.04 ships rofi 1.7 (X11-only), GLFW 3.3, cargo 1.75 and
   sway 1.9. Expect source builds.

---

## 3. Maintaining both configurations

- **Shared:** the i3 scripts reused through `$I3_SCRIPT`, `config/i3/share` (wallpapers,
  icons, lists), and the app configs (kitty, rofi, dunst, conky, ranger, zathura). A change
  there affects both window managers. Keep them free of X11-only and Wayland-only commands,
  or use the "Wayland tool first, X11 fallback" pattern (ranger `yf`, zathura `Ctrl+c`).
- **i3-only / sway-only:** `config/i3/config*` and `config/sway/config*`. A new i3 binding
  needs its sway twin. Keep the same mode labels, and put new modes in
  `sway_mode_name.config`.
- **New script:** if it touches displays, input, windows by X id, the clipboard,
  screenshots or the i3 config files, write a `sway_` version with the same CLI. Otherwise
  call the `i3_` script from sway as well.
- **After editing the sway config:**
  1. `sway -C -c ~/.config/sway/config` (syntax)
  2. reload with Mod+Shift+r
  3. `~/.config/sway/script/sway_session_check.sh` in a terminal (environment)
- **Input-method problems:** `sway_input_method.sh status`, then `doctor`
  (`~/sway_im_doctor.txt`).
- **Screenshot problems:** `$XDG_RUNTIME_DIR/sway_screenshot.log`.
- **Session log:** `~/.local/state/sway.log`.
