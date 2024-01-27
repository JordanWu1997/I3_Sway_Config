# MPV_Config
My MPV player configuration files.
Modified from https://github.com/Tsubajashi/mpv-settings.

## Configuration Files
- `$HOME/.config/mpv/scripts/`: Where you put plug-in files
- `$HOME/.config/mpv/script-opts/`: Where you put plug-in file configurations
- `$HOME/.config/mpv/input.conf`: Where you set all the keybindings
- `$HOME/.config/mpv/mpv.conf`: Where you put all the MPV settings

## Keybinding

| Key Mapping                      | Function                                           | Description | Note |
| :------------------------------: | :------------------------------------------------: | :---------: | :--: |
| `[Ctrl/None/Alt]`+`[Left/Right]` | Seek 1/10/60 sec backward/forward                  |             |      |
| `[Ctrl/None/Alt]`+`[j/l]`        | Seek 1/10/60 sec backward/forward                  |             |      |
| `[Space/k]`                      | Pause-Play                                         |             |      |
| `[,/.]`                          | Previous/Next frame                                |             |      |
| `[None/Shift/Alt]`+`[;]`         | Toggle A-B/current_file/current_playlist loop      |             |      |
| `[Alt]`+`[Shift]`+`[h/j/k/l]`    | Pan left/down/up/right                             |             |      |
| `[-/=/+]`                        | Zoom in/out/back_to_original                       |             |      |
| `[a]`                            | Cycle audios                                       |             |      |
| `[b]`                            | Cycle subtitles                                    |             |      |
| `[t]`                            | Seek to specific time                              |             |      |
| `[g]`                            | Toggle aspect ratio                                |             |      |
| `[f]`                            | Toggle full-screen mode                            |             |      |
| `[None/Shift/Ctrl]`+`[s]`        | Video_with_sub/Video_without_sub/Window screenshot |             |      |
| `[Shift]`+`[i]`                  | Toggle MPV video information                       |             |      |
| `[Shift]`+`[o]`                  | Toggle MPV on-screen-display (OSD)                 |             |      |
| `[Shift]`+`[Enter]`              | Open playlist                                      |             |      |
| `[Backspace]`                    | Remove selected files from playlist                |             |      |
| `[Ctrl]`+`[o]`                   | Open `mpv-file-browser`                            |             |      |

### [mpv-file-browser](https://github.com/CogentRedTester/mpv-file-browser)

| Key Mapping         | Function                       | Description | Note |
| :-----------------: | :----------------------------: | :---------: | :--: |
| `[s]`               | Enter select mode              |             |      |
| `[Shift]`+`[s]`     | Unselect file                  |             |      |
| `[Left/Right]`      | Go to Parent/Child directory   |             |      |
| `[Shift]`+`[Enter]` | Add selected files to playlist |             |      |

# Reference
- https://github.com/mpv-player/mpv/blob/master/etc/input.conf (MPV default keybindings)
- https://mpv.io/manual/master/#files (MPV configuration files)
- https://github.com/stax76/awesome-mpv (MPV plug-in/settings collections)
- https://mpv.io/manual/master/#script-location (MPV scripts)
- https://github.com/Tsubajashi/mpv-settings (other MPV user settings)
- https://github.com/CogentRedTester/mpv-file-browser (MPV file-browser plug-in)
- https://github.com/po5/thumbfast (MPV thumbnail previewr plug-in)
- https://github.com/jonniek/mpv-playlistmanager (MPV playlist plug-in)
