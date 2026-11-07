# i3 desktop workflow

This review follows the current i3 config, mode definitions, Omnisearch scripts, the system
status script, ranger bindings, and the LocalSend integration (reviewed 2026-11-07). The
charts summarize navigation; each mode contains more commands than are drawn here.

- [Whole desktop workflow](I3_DESKTOP_WORKFLOW.svg) · [source](I3_DESKTOP_WORKFLOW.dot)
- [i3 mode and Rofi overview](I3_WORKFLOW_FSM.svg) · [source](I3_WORKFLOW_FSM.dot)
- [All 103 i3 mode states](I3_MODE_FSM_ALL.svg) · [source](I3_MODE_FSM_ALL.dot), generated
  from the config by [`tools/gen_mode_fsm.py`](tools/gen_mode_fsm.py)
- [Omnisearch menu and search flows](OMNISEARCH_WORKFLOW.md)

The sway configuration mirrors this workflow key for key. The differences are listed in
`config/sway/doc/07_I3_SWAY_CORRESPONDENCE.md`.

## How the pieces fit

| Entry | Path | Return or exit |
| --- | --- | --- |
| Session start | Display profile, applets, input, notifications; 8 s later a **login summary** notification | Summary lists volume, caffeine, autotiling, bar mode, focus mode, anything that needs attention, and the help keys |
| Normal i3 | Direct window, workspace, scratchpad, app, and terminal shortcuts | Stays in normal bindings |
| i3 modes | System, Toolkit, Display, media, window, workspace, customization, and other mode families (19 entered from normal) | Enter generally goes to the parent; Escape goes to normal; most also accept Ctrl+[ |
| Insert mode | Ctrl+Alt+I or Super+Ctrl+I | **Toggle:** the same keys, or Ctrl+[, return to normal |
| Keybinding help | Super+Shift+/ | Keybindings menu (Shortcut guide / All keybindings); Escape continues to the Omnisearch Search menu, Escape again closes |
| System status | Ctrl+Alt+S, then `s` | One read-only Rofi view with tabs **Devices · Session · Background**; ⚠ marks rows that need attention and the header names their tabs. Ctrl+Tab or Shift+←/→ switch tabs; Enter or Escape closes |
| Caffeine | Ctrl+Alt+T, then Shift+C | `1`/`2` enable/disable now; `s` sets the startup default (`1`/`2`), Enter goes back to Caffeine |
| Toolkit LocalSend | Ctrl+Alt+T, then `l` | Opens `localsend-cli` in a floating terminal; i3 returns to normal |
| Ranger send | Ctrl+Alt+2 to open ranger, mark files if needed, then `,s` | LocalSend device picker runs in ranger's terminal; ranger redraws afterwards. A selected directory is archived before sending |
| Ranger receive | In ranger, enter the destination directory, then `,r` | Temporary receiver with the current directory as destination; stop it or finish a transfer to return to ranger |
| Omnisearch | Super+Backslash | One flat, two-column Search menu with Find, Open, Tool, Go, Help, and System prefixes; Escape backs up one layer, Alt+B returns to Search, Escape at Search closes |
| Direct Rofi actions | Window, mark, workspace, display, and other selectors | Usually close on Escape and return to the i3 mode that launched them, unless that binding switches to normal |

The Bumblebee status bar shows status and workspace names. A separate i3 bar shows
binding-mode context; keeping them separate is an intentional reduction in status-bar
clutter. The workspace selector temporarily reveals the mode bar and restores its previous
hidden state afterwards.

## Review findings (2026-11-07)

1. **System `h` (session health) is gone.** Since the status rework, `s` shows one view
   with Devices, Session and Background tabs. The previous charts still showed `s / h`;
   they are updated.
2. **Insert mode is a toggle.** Ctrl+Alt+I and Super+Ctrl+I now also leave Insert mode, as
   its label says. The charts said only Ctrl+[.
3. **New entry points:** Super+Shift+/ opens the keybinding help directly, and the login
   summary notification points to it. Both are added to the overview and desktop charts
   and to the Omnisearch map.
4. **New mode:** Caffeine → `s` (set startup default) makes 103 modes. The full chart is
   now generated from the config, so mode counts, entry keys and Enter-to-parent edges
   cannot drift from the bindings again. Its source links point to `../../config.d/…`;
   the old hand-made links pointed one directory too high.
5. **Consistent as before:**
   - Repeatable adjustments stay in their mode; one-off System and Toolkit actions return
     to normal.
   - Open URL and its AI/Research children describe their batch behavior in the label.
   - Every mode is reachable from normal, and every mode has a label.
   - Ranger's LocalSend keys (`,s`, `,r`) match the shortcut guide.

`i3 -C -c config/i3/config` accepts the config (i3 4.24). The generator reports 103 modes,
124 entry edges, 85 Enter-to-parent edges, and no unreachable or undefined modes. This is a
static review; it does not prove live focus, hotplug, or transfer behavior.

Modes that are deliberately kept out of this repository are left out of the charts. They
are listed in `HIDDEN_MODES` in `tools/gen_mode_fsm.py`.

## Regenerating the charts

```bash
cd config/i3/doc/workflow
python3 tools/gen_mode_fsm.py --summary            # counts, undefined/unreachable modes
python3 tools/gen_mode_fsm.py > I3_MODE_FSM_ALL.dot
for f in *.dot; do dot -Tsvg "$f" -o "${f%.dot}.svg"; done
```

The other `.dot` files are written by hand. Update them when a top-level key, the System or
Toolkit menu, Omnisearch navigation, or the ranger/LocalSend flow changes.
