# Multiplexer_Configs [Need to reorganized ... Not Maintained for now ...]
Here's my multiplexer config files (including TMUX and I3-WM)
## Part 1 - TMUX (Terminal MUltiPlexer)
### 1-1 TMUX Config Usage
- Change ```tmux.conf``` to ```.tmux.conf``` and store it in __user's home directory__
### 1-2 TMUX Powerline Installation
Here use Fedora as OS
- __in terminal__, run ```dnf install tmux-powerline```
- If you can't install tmux-powerline successfully, you can just use powerline.conf
- But remember to change the line ```source /usr/share/tmux/powerline.confthe path``` to where you store powerline.conf
### 1-3 TMUX Plugins Installation
Here use Tmux Plugin Manager (TPM) as plugin-manager
- TPM installation
  - ```git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm```
  - __in terminal__, run ```tmux```, and then __in tmux__, run ```source-file ~/.tmux.conf```
- Plugin installation
  - __in tmux__, press ```Ctrl+space``` + ```I```, and then auto-installation will start
  - Note: it won't show information at first, but it will show up in the end
### 1-4 TMUX Hotkeys (Modified)
Modified bindkey: ```Ctrl+space``` (default: ```Ctrl+b```)
- Refresh tmux configuration (.tmux.conf): bind + ```r```
- Show all sessions: bind + ```s```
- Show all windows: bind + ```w```
- Create window: bind + ```c```
- Kill window: bind + ```x```
- Create vertically split panel: bind + ```|```
- Create horizontally split panel: bind + ```_```
- Swap window number ([left]/[right]): bind + ```shift+[left]/[right]```
- Swap panel (back/forth): bind + ```{/}```
- Resize panel ([left]/[up]/[down]/[right]): ```bind+[<]/[+]/[-]/[>]```
- VIM-like Hokeys
  - Switch pane focus ([left]/[up]/[down]/[right]): ```bind+[h]/[j]/[k]/[l]```
  - Copy:
    - Enter copy mode: ```bind+[```
    - Press ```Shift+v``` into v-mode in vim
    - Select the region to copy then press ```y``` to copy
  - Paste: ```bind+]```
### 1-5 TMUX Tips
- Detach session: __in tmux__, press bind + ```d```
- Show all sessions: __in terminal__, run ```tmux ls```
- Reattach session: __in terminal__, run ```tmux a -t NAME_OF_SESSION```
- Rename window: __in tmux__, press bind + ```,``` then enter name to change
- Rename session: __in tmux__, press bind + ```:``` then enter ```rename-session NAME_OF_SESSION```

## Part 2 - I3WM (I3 Windows Manager)
### 2-1 I3WM Config Usage
This is main configuration for i3wm, containing hotkeys and user interface
- Change ```i3_config``` to ```config``` and store it in __{user's home}/.config/i3/__
### 2-2 I3status Config Usage (Not Used Anymore)
This is configuration for status bar in i3wm
- Change ```i3status_config``` to ```config``` and store it in __{user's home}/.config/i3status/__
### 2-3 I3WM Hotkeys (Cheat Sheet)
Modified bindkey: WIN(super)
- System
  - Exit i3wm ```bind+shift+e```
  - Execute i3wm command ```bind+shift+i```
  - Toggle status bar ```bind+b```
  - Kill window ```alt+F4``` for ```bind+shift+q```
  - Poweroff/Reboot/Lock ```bind+Esc```
  - Lock ```ctrl+alt+l```
  - Screenshot: ```bind+Print```
  - Screenshot (Interactive): ```bind+shift+Print```
  - Reload I3WM configuration: ```bind+shift+c```
  - Reload I3WM: ```bind+shift+r```
- Change Focus
  - Change workspace focus
    - Direct: ```bind+NUM_OF_WORKSPACE```
    - Back/Forth: ```bind+[tab]/[Shift+tab]```
  - Change window focus
    - Static window: vim-like, ```bind+[h]/[j]/[k]/[l]```
    - Static <-> floating: ```bind+[space]/[shift+space]```
  - Change container focus
    - Parent container: ```bind+a```
    - Child container: ```bind+shift+a```
- Open applications:
  - Terminal: ```bind+enter```
  - Application menu: ```bind+d```
- Resize
  - Resize window: ```bind+r```
- Rename
  - Rename workspace: ```bind+y```
  - Rename window: ```bind+p```
- Move
  - Move window: vim-like, ```bind+shift+[h]/[j]/[k]/[l]```
  - Move windows to diff workspace: Focus window then ```bind+NUM_OF_WORKSPACE```
  - toggle window split style (vertical/horizontal): ```bind+e```
- Change layout
  - Change container layout
    - stacking: ```bind+s```
    - tabs: ```bind+w```
    - toggle split: ```bind+e```
- Toggle fullscreen
  - Toggle window fullscreen: ```bind+f```
- Move window background/foreground
  - Move window to scratchpad (background): ```bind+-```
  - Move window out from scratchpad (foreground): ```bind+=```
  - Move all windows to scratchpad (background): ```bind+x```
  - Move all windows out from scratchpad (foreground): ```bind+shift+x```
### 2-4 I3WM Tips
- Set wallpapers (Using feh)
  - Random wallpapers (same for all): ```bind+m```
  - Random wallpapers (diff for all): ```bind+shift+m```
- Save/Load i3 workspace layout
  - Save layout
    - __In terminal__:```i3-resurrect save -w $WORKSPACE```
    - __In terminal__:```i3-resurrect restore -w $WORKSPACE```
- Swap i3 workspace
  - __In i3__: switch to workspace to be swapped
  - __In terminal__:```i3-workspace-swap -d $WORKSPACE```
## Part 3 - Demo
<img src='./i3_demo.png'></img>
- Applications
  - figlet, ranger, cmatrix
  - htop, vis, neofetch, htop, conky
## Part 4 - Reference
### TMUX part
- https://github.com/shengjunlin/tmux_config
### I3WM part
- https://i3wm.org/docs/userguide.html
- https://github.com/levinit/i3wm-config
- https://www.itread01.com/p/142448.html
- https://github.com/snickerton/DotfilesSucculent
### Wallpaper credit
- https://www.eso.org/public/images/archive/category/alma/
