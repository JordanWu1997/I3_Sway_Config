# I3 Share Directory

Table of Contents
=================

* [I3 Share Directory](#i3-share-directory)
   * [Texts](#texts)
   * [Images](#images)
      * [Default Wallpapers](#default-wallpapers)
      * [Logos](#logos)
      * [Icons](#icons)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# Context

## Texts
- `app-icons.json`
    - Unicode list for applications (required by [i3-workspace-names-daemon](https://github.com/cboddy/i3-workspace-names-daemon))
- `i3_automark_list`
    - Single character mark list that is
        - Used by `../script/i3_automark.py` to assign mark to every window
        - Used as the input list for rofi selector in `../script/i3_mark_operator.sh`
    - In rofi, it starts from the left to the right and from the first row to the last row of __QWERTY__ keyboard
        - Alphabet only, except for single quotation

## Images
- `default_wallpaper`
    - Image for `pywal`/`feh` startup wallpaper
    - Set by `../script/i3_wallpaper_operator.sh`

### Default Wallpapers
<details open>

- `default_fedora_wallpaper_1.png`
![alt_text](./default_fedora_wallpaper_01.png)
- `default_fedora_wallpaper_2.png`
![alt_text](./default_fedora_wallpaper_02.png)
- `default_i3_wallpaper.png`
![alt_text](./default_i3_wallpaper.png)
- `default_thinkpad_wallpaper.png`
![alt_text](./default_thinkpad_wallpaper.png)

</details>

### Logos
<details open>

- `fedora_logo_darkbackground.png`
![alt_text](./fedora_logo_darkbackground.png)
- `fedora_logo_white.png`
![alt_text](./fedora_logo_blue.png)
- `fedora_logo_blue.png`
![alt_text](./fedora_logo_white.png)

</details open>

### Icons
<details open>

[<img src="./lightbulb_icon.png" width="250"/>](./lightbulb_icon.png)
[<img src="./mute_icon.png" width="250"/>](./mute_icon.png)
[<img src="./volume_icon.png" width="250"/>](./volume_icon.png)

</details>
