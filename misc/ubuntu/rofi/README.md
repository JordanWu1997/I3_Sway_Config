# Rofi_Config
My customized rofi (multi-purpose selector) configuration files

Table of Contents
=================

* [Rofi_Config](#rofi_config)
* [Context](#context)
   * [Configurations](#configurations)
   * [Text file](#text-file)
   * [Customized Rofi Keybindings](#customized-rofi-keybindings)
   * [Rofi Tips:](#rofi-tips)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# Context

## Configurations
- `config.rasi`
    - Configuration for fullscreen wal-themed rofi with max 3 columns
    - Main usage: application launcher, executable launcher
- `config_single_col.rasi`
    - Configuration for fullscreen wal-themed rofi with max 1 columns
    - Main usage: window selector, binding key maps
    - Note: release `[Alt]`+([`Shift]`)+`[Tab]` as enter for convention
- `config_i3mark.rasi`
    - Configuration for rectangle box wal-themed rofi with pre-defined single-character input
    - Main usage: i3 mark selector
    - Note: for pre-defined input list, check `configs/i3/share/i3_automark_list.txt`
- `config_dracula.rasi`
    - Configuration for Dracula-themed rofi
    - Main usage: miscellaneous (for Dracula-themed environment)

## Text file
- `i3_automark_list.txt`
    - Single character mark list that
        - Record marks used in `../../config/i3/script/i3_automark.py` to automatically assign mark to every window
        - Is used as the input list for rofi selector in `../../config/i3/script/i3_mark_operator.sh`
    - In rofi, it starts from the left to the right and from the first row to the last row of __QWERTY__ keyboard
        - Alphabet only, except for single quotation (')

## Customized Rofi Keybindings
- `[Ctrl]`+`[c/g/[]`: Exit rofi
- `[Alt]`+([`Shift]`)+`[Tab]`: Select row (up)/down
- `[Ctrl/Alt]`+`[h/j/k/l]`: Select left/down/up/right
- `[Ctrl/Alt]`+`[Space]`: Enter selected item

## Rofi Tips:
- Auto-selection (select if there is only one option) is disabled in configurations except `config_i3mark.rasi`
- Auto-selection can be enabled by adding `-auto-select` flag
