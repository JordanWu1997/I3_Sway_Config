# Theme
16-color theme templates and color files generated by color file generator

Table of Contents
=================

* [Theme](#theme)
* [Table of Contents](#table-of-contents)
* [Context](#context)
   * [Script Usage](#script-usage)
      * [Installation (Required for first time usage)](#installation-required-for-first-time-usage)
      * [Details of generating color files](#details-of-generating-color-files)
      * [Apply color files](#apply-color-files)
   * [Reference](#reference)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# Context

## Script Usage

### Installation (Required for first time usage)

- `./install.sh`
    - Includes
        - `./copy_wal_templates.sh`: copy color template from [pywal](https://github.com/dylanaraps/pywal):
        - `./generate_color_files_for_template.sh`: generate color files based on pywal colorschemes

### Details of generating color files

- `./generate_color_files_for_template.sh`
    - Input: 16-color template
        - 16-color template as `./NAME_OF_TEMPLATE/NAME_OF_TEMPLATE_colors`, containing 16 rows
            - row 1~8: Black, Red, Green, Yellow, Blue, Magenta, Cyan, White
            - row 9~16: Bright Black, Bright Red, Bright Green, Bright Yellow, Bright Blue, Bright Magenta, Bright Cyan, Bright White
        - Output color files will be stored in `./NAME_OF_TEMPLATE`
    - Input: options
        1. `./color_files`
            - Color file templates (`./color_files`)
        2. `16` or `9`
            - 16-color template
            - 9-color template (bright color only)
        3. `apply_now` or ` ` (nothing)
            - Replace wal color files (`$HOME/.cache/wal/*`) with new generated files
    - Output: color files
        1. `color`
            - Required by `conky`
        2. `colors-kitty.conf`
            - Required by `kitty`
        3. `colors-rofi-dark.rasi`
            - Required by `rofi`
        4. `colors.json`
            - Required by `bumblebee-status`
        5. `color.sh`
            - Required by `vis`
        6. `colors.Xresources`
            - Required by `i3` and other X window applications

### Apply color files
- `./apply_template_theme.sh`
    - Use existing color files in `./templates/`
    - Copy colors files to `$HOME/.cache/wal/` to replace original wal color files

## Reference
- https://en.wikipedia.org/wiki/Xrdb
- https://www.reddit.com/r/i3wm/comments/76p3tg/color_scheme_not_loading_set_from_resource_upon/
- https://github.com/morhetz/gruvbox
- https://draculatheme.com/
- https://github.com/dylanaraps/pywal