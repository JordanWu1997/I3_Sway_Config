# MPV_Config
My MPV player configuration files.
Modified from https://github.com/Tsubajashi/mpv-settings.

## Configuration Files
- `$HOME/.config/mpv/scripts/`: Where you put plug-in files
- `$HOME/.config/mpv/script-opts/`: Where you put plug-in file configurations
- `$HOME/.config/mpv/input.conf`: Where you set all the keybindings
- `$HOME/.config/mpv/mpv.conf`: Where you put all the MPV settings

## Keybinding
- Keybindings

| Key Mapping                                | Function                                                   | Description | Note                                                                   |
| :----------------------------------------: | :--------------------------------------------------------: | :---------: | :--------------------------------------------------------------------: |
| `[Ctrl/None/Alt]`+`[Left/Right]`           | Seek 1/10/60 sec backward/forward                          |             |                                                                        |
| `[Ctrl/None/Alt]`+`[j/l]`                  | Seek 1/10/60 sec backward/forward                          |             |                                                                        |
| `[Alt]` + `[1-9/0] `                       | Seek to 10%-90%/0% in current playing                      |             |                                                                        |
| `[Space/k]`                                | Pause-Play                                                 |             |                                                                        |
| `[,/.]`                                    | Previous/Next frame                                        |             |                                                                        |
| `[[/]/Backspace]`                          | Decrease/Increase/Reset play speed                         |             |                                                                        |
| `[None/Shift/Alt]`+`[;]`                   | Toggle A-B/current_file/current_playlist loop              |             |                                                                        |
| (`[Ctrl]`)+`[Alt]`+`[Shift]`+`[h/j/k/l/o]` | Pan left/down/up/right/back_to_original                    |             | `[Ctrl]`+`[Alt]`+`[Shift]`+`[h/j/k/l/o]` conflicts with my i3 bindkeys |
| (`[Ctrl]`)+(`[Alt]`)+`[-/=/+]`             | Zoom in/out/back_to_original                               |             | `[Ctrl]`+`[Alt]`+`[Shift]`+`[-/=/+]` conflicts with my i3 bindkeys     |
| (`[Ctrl/Alt]`)+(`[Shift]`)+`[r]`           | Rotate clock-wisely                                        |             | Step in (+/-)(1/15/90) degrees                                         |
| `[x]`                                      | Cycle audios                                               |             |                                                                        |
| `[c]`                                      | Cycle subtitles                                            |             |                                                                        |
| `[t]`                                      | Seek to specific time                                      |             |                                                                        |
| `[g]`                                      | Toggle aspect ratio                                        |             |                                                                        |
| `[f]`                                      | Toggle full-screen mode                                    |             |                                                                        |
| `[Ctrl]`+(`[Shift]`)+`[r]`                 | Rotate (anti-)clockwisely ,                                |             |                                                                        |
| `[None/Shift/Ctrl]`+`[s]`                  | Video_with_sub/Video_without_sub/Resized_window screenshot |             |                                                                        |
| `[Shift]`+`[i]`                            | Toggle MPV video information                               |             |                                                                        |
| `[Shift]`+`[o]`                            | Toggle MPV on-screen-display (OSD)                         |             |                                                                        |
| `[b]`                                      | Cycle MPV progress bar location top/center/bottom          |             |                                                                        |
| `[Shift]`+`[Enter]`                        | Open playlist                                              |             |                                                                        |
| `[Ctrl]`+`[o]`                             | Open `mpv-file-browser`                                    |             |                                                                        |

### [playlistmanger](https://github.com/jonniek/mpv-playlistmanager)
- Modify keybindings in `$HOME/.config/mpv/script-opts/playlistmanager.conf`
    ```
    ...
    key_moveup=k
    key_movedown=j
    key_selectfile=SPACE SPACE
    key_unselectfile=
    key_playfile=ENTER
    key_removefile=d
    key_closeplaylist=q
    ...
    ```
- Keybindings

| Key Mapping     | Function                        | Description                                | Note |
| :-------------: | :----------------------------:  | :----------------------------------------: | :--: |
| `[q]`           | Close file-browser              |                                            |      |
| `[j/k]`         | Scroll down/up                  |                                            |      |
| `[Enter]`       | Play file                       |                                            |      |
| `[Space]`       | Toggle select file              | Use [j/k] to move selected file            |      |
| `[d]`           | Remove file from playlist       |                                            |      |
| `[Ctrl]+[p/n]`  | Play prev/next file in playlist | You can also use `[Shift]`+`[k/j]`         |      |
| `[Ctrl]+[e]`    | Export current playlist         | Save playlist to `~/.config/mpv/playlists` |      |
| `[r]`           | Sort playlist                   |                                            |      |
| `[Shift]`+`[r]` | Shuffle playlist                |                                            |      |
| `[Alt]+[r]`     | Reverse playlist                |                                            |      |
| `[l]`           | Load file in current directory  |                                            |      |

### [mpv-file-browser](https://github.com/CogentRedTester/mpv-file-browser)
- Modify keybindings in `$HOME/.config/mpv/scripts/mpv-file-browser/modules/keybinds.lua`
    ```lua
    ...
    g.state.keybinds = {
        ...
        {'q',           'close',        controls.escape},
        {'l',           'down_dir',     movement.down_dir},
        {'h',           'up_dir',       movement.up_dir},
        {'j',           'scroll_down',  function() cursor.scroll(1, o.wrap) end,           {repeatable = true}},
        {'k',           'scroll_up',    function() cursor.scroll(-1, o.wrap) end,          {repeatable = true}},
        {'v',           'select_mode',  cursor.toggle_select_mode},
        {'Space',       'select_item',  cursor.toggle_selection},
        ...
    }
    ...
    ```
- Keybindings

| Key Mapping         | Function                          | Description | Note |
| :-----------------: | :-------------------------------: | :---------: | :--: |
| `[q]`               | Close file-browser                |             |      |
| `[v]`               | Enter select mode                 |             |      |
| `[Space]`           | Toggle select file                |             |      |
| `[h/l]`             | Go to Parent/Child directory      |             |      |
| `[j/k]`             | Scroll down/up                    |             |      |
| `[Shift]`+`[Enter]` | Append selected files to playlist |             |      |

### [mpv-webm](https://github.com/ekisu/mpv-webm)
- Keybindings

| Key Mapping         | Function                       | Description | Note |
| :-----------------: | :----------------------------: | :---------: | :--: |
| `[Shift]`+`[w]`     | Video clipper (in webm format) |             |      |

### [visualizer](https://github.com/mfcc64/mpv-scripts/blob/master/visualizer.lua)
- Keybindings

| Key Mapping         | Function         | Description | Note |
| :-----------------: | :--------------: | :---------: | :--: |
| `[Shift]`+`[d]`     | Audio visualizer |             |      |

### [SmartCopyPaste](https://github.com/Eisa01/mpv-scripts#smartcopypaste-ii-script)
- Keybindings

| Key Mapping    | Function                              | Description | Note |
| :------------: | :-----------------------------------: | :---------: | :--: |
| `[Ctrl]`+`[v]` | Append URL in clipboard to playlist   |             |      |
| `[Ctrl]`+`[c]` | Copy current playing URL to clipboard |             |      |

## Miscellaneous
- MPV on linux has a weird hidden title bar when running picom
    - You need to set `frame-opacity = 1.0` in `$HOME/.config/picom/picom.conf` to eliminate it.

# Reference
- https://github.com/mpv-player/mpv/blob/master/etc/input.conf (MPV default keybindings)
- https://mpv.io/manual/master/#files (MPV configuration files)
- https://github.com/stax76/awesome-mpv (MPV plug-in/settings collections)
- https://mpv.io/manual/master/#script-location (MPV scripts)
- https://github.com/Tsubajashi/mpv-settings (other MPV user settings)
- https://github.com/CogentRedTester/mpv-user-input/tree/master (MPV user input plug-in)
- https://github.com/CogentRedTester/mpv-file-browser (MPV file-browser plug-in)
- https://github.com/po5/thumbfast (MPV thumbnail previewr plug-in)
- https://github.com/jonniek/mpv-playlistmanager (MPV playlist plug-in)
- https://github.com/hacel/recent (MPV recent file plug-in)
- https://github.com/ekisu/mpv-webm (MPV video clipper plug-in)
- https://github.com/Eisa01/mpv-scripts#smartcopypaste-ii-script (MPV scripts: SmartCopyPaste)
