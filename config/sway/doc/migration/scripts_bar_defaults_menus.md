# Sway migration: bar / default values / gaps / borders / decorators / dunst / menus

All new scripts live in `config/sway/script/` (deployed as `~/.config/sway/script`).
Each one keeps the subcommands and arguments of its i3 version, so a binding
`$I3_SCRIPT/i3_<x>.sh <args>` becomes `$SWAY_SCRIPT/sway_<x>.sh <args>`.
Shared assets (icons, workspace list) stay in `~/.config/i3/share`.

## Scripts

| sway script | ported from | status |
|---|---|---|
| sway_bar_operator.sh | i3_bar_operator.sh | All subcommands work. `bar_reload` / `bar_refresh_with_crontab` now run `swaymsg reload`, which respawns every swaybar but also reloads the whole config (runtime gaps and similar settings go back to their defaults). |
| sway_bar_decorator.sh | i3_bar_decorator.sh | All work (`i3`, `pywal`). It rewrites colors by key name instead of fixed line offsets. |
| sway_default_valuechanger.sh | i3_default_valuechanger.sh | All keys work. `picom` only switches the `~/.config/picom/picom.conf` link and runs `swaymsg reload` (see "Opacity" below). |
| sway_gap_operator.sh | i3_gap_operator.sh | All work. |
| sway_border_operator.sh | i3_border_operator.sh | All work. |
| sway_window_decoractor.sh | i3_window_decoractor.sh | All work (`default`, `monochromic`, `dirchromatic`, `monochromic_inversed`). |
| sway_genereate_workspace_name_list.sh | i3_genereate_workspace_name_list.sh | Works. Writes `~/.config/i3/share/sway_workspace_name_list.txt`. |
| sway_rofi_omnisearch.sh | i3_rofi_omnisearch.sh | Works. Changed: clipboard (wl-copy), Windows (swaymsg tree with app_id or class), Workspaces, Marks, bar_mode hidden_state, and the keybinding page, which now reads the sway config. Clipboard history uses cliphist and falls back to parcellite. |
| sway_pdf_menu.sh | i3_pdf_menu.sh (sourced by omnisearch) | Works. Tracking and closing the sioyek window now uses swaymsg con_id. wl-paste replaces xclip. |
| sway_pdf_keyword_search.sh | i3_pdf_keyword_search.sh | Works. It now calls sway_rofi_omnisearch.sh. |
| sway_dunst_operator.sh | i3_dunst_operator.sh | All work. It reads values from the sway config, and the logger is started with `swaymsg exec`. |
| sway_autotiling_operator.sh | i3_autotiling_operator.sh | All work. It edits sway_startup.config. |

No subcommand is stubbed.

Not ported, because they are display-server independent: i3_omnisearch_cache.py and
i3_pdf_search.py (used from `$I3_SCRIPT`), i3_vis_colorchanger.sh,
i3_diff_check_operator.sh (filesystem only), and i3_check_program_version.sh (it
still prints i3/i3bar versions, which is harmless; nothing binds it).

## Config line formats the scripts edit

- `~/.config/sway/config`: `set $<name> <value>`. The first line where `$1=="set"`
  and `$2=="$<name>"` is replaced. Names used: `default_font`, `default_outer_gap`,
  `default_inner_gap`, `default_border_width`, `default_titlebar_style`,
  `default_floating_titlebar_style`, `default_titlebar_fontsize`,
  `default_i3bar_height`, `default_i3bar_fontsize`, `default_i3bar_mode`,
  `default_i3bar_position`, `default_conky_startup`,
  `default_conky_system_alignment`, `default_conky_bindkey_alignment`. These are
  read but not written: `default_conky_gap_y` (bar operator) and
  `default_border_width` / `default_i3bar_*` / `default_*_gap` (dunst operator).
- `config.d/sway_startup.config`:
  - `exec $SWAY_SCRIPT/sway_toolkit_operator.sh enable_caffeine|disable_caffeine`.
    Regex: `^#\?\(exec .*sway_toolkit_operator\.sh \)\(enable\|disable\)_caffeine.*`.
    Only the caffeine line is touched.
  - `exec $SWAY_SCRIPT/sway_flashfocus_operator.sh start`. A leading `#` toggles it.
    Regex: `^#\?exec .*sway_flashfocus_operator\.sh start`.
  - `exec_always pgrep -u "$USER" -x autotiling >/dev/null || autotiling [--limit 2]`.
    The first line matching `^#?exec_always .*autotiling` is rewritten.
- `config.d/sway_gap.config`: the first line whose first field contains
  `smart_gaps`, written as `smart_gaps on`, `smart_gaps inverse_outer` or
  `#smart_gaps on`.
- `config.d/sway_window.config`:
  - The first line whose first field contains `hide_edge_borders`, written as
    `hide_edge_borders none|both|vertical|horizontal|smart|smart_no_gaps`. There must
    be no commented `#hide_edge_borders` line before the active one.
  - A `Color Palette` marker comment, followed by the first `client.focused`,
    `client.focused_inactive`, `client.unfocused`, `client.urgent`,
    `client.placeholder` and `client.background` lines after it.
- `config.d/sway_bar.config`:
  - A comment containing `bar_status workspace color` (and one containing
    `bar_mode workspace color`) right before each bar's `colors {` block. Inside the
    block up to the closing `}`, these keys are rewritten, with or without a leading
    `#`: background, statusline, separator, focused_workspace, active_workspace,
    inactive_workspace, urgent_workspace, binding_mode.
  - A status_command continuation line containing `bumblebee-status theme`, written
    as `        -t <theme> # bumblebee-status theme`.
- `config.d/sway_workspace_name.config` (read only): `set $wsN "name"`.

## Required sway config changes

- Point the bindings and startup lines at the sway scripts:
  - bar mode bindings, `Mod4+b` bar_toggle and theme bindings → `$SWAY_SCRIPT/sway_bar_operator.sh` and `sway_bar_decorator.sh`
  - gap option → `sway_gap_operator.sh`
  - border and window decoration modes → `sway_border_operator.sh` and `sway_window_decoractor.sh`
  - `*_valuechanger.sh` → `sway_default_valuechanger.sh`
  - dunst logger bindings → `sway_dunst_operator.sh`
  - autotiling bindings → `sway_autotiling_operator.sh`
  - `Mod4+backslash` and `Mod4+Shift+slash` → `sway_rofi_omnisearch.sh [--keybindings]`
  - workspace list: startup line plus the `Shift+r` binding (sway_mode.config still calls the i3 version) → `sway_genereate_workspace_name_list.sh`
- A bar with `id bar_mode` must exist, because omnisearch toggles its hidden_state.
- Define `set $transp #00000000` (or similar). The decorator writes
  `client.background $transp`, as the i3 version did. sway ignores the line, but
  the variable should exist.
- For omnisearch clipboard history: `exec wl-paste --watch cliphist store`.
- Opacity: `sway_default_valuechanger.sh picom <transparency|blur>` sets
  `~/.config/picom/picom.conf -> picom_<mode>.conf` and runs `swaymsg reload`.
  sway_opacity_operator.sh (`default` and `after_i3_restart`) must read that link to
  pick its default mode. The binding should stay
  `... sway_default_valuechanger.sh picom blur; exec $SWAY_SCRIPT/sway_opacity_operator.sh blur`.
- Other agents' scripts should read the workspace list from
  `~/.config/i3/share/sway_workspace_name_list.txt`: sway_workspace_operator.sh,
  and the ports of i3_new_workspace.sh.
- `sway_bar_operator.sh` uses `$SWAY_SCRIPT/sway_conky_valuechanger.sh` if it exists,
  otherwise `$I3_SCRIPT/i3_conky_valuechanger.sh`.

## Packages

- apt (Ubuntu 24.04): sway, jq, wl-clipboard, cliphist, libnotify-bin, dunst,
  fontconfig, conky-all, fd-find, ripgrep, pdfgrep, sqlite3, poppler-utils, python3,
  xdg-utils. Also rofi ≥ 2.0 (Wayland): Ubuntu 24.04 ships 1.7.5, which is X11 only,
  so build rofi ≥ 2.0 or lbonn/rofi-wayland from source. Optional: autotiling (pipx),
  sioyek, kitty.
- dnf (Fedora): sway, jq, wl-clipboard, cliphist, libnotify, dunst, fontconfig,
  conky, fd-find, ripgrep, pdfgrep, sqlite, poppler-utils, python3, xdg-utils, rofi
  (≥ 2.0 has Wayland support; on older releases use rofi-wayland). Optional:
  autotiling, sioyek, kitty.
