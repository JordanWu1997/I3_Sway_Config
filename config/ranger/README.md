# Ranger Config
My ranger configuration file and post-installation

# Context

## Configs

## Post-installation

### preview tool installation

#### PDF

```sh
# pdf preview
sudo dnf install poppler-utils pdftoppm
```

#### Text, Word, Excel, Markdown

```sh
# word/odt preview
sudo dnf install odt2txt
# excel preview
sudo dnf install catdoc
# markdown preview
sudo dnf install pandoc
```

#### HTML

```sh
# html preview
sudo dnf install w3m
```

#### Image

```sh
# image preview
sudo dnf install w3m-img imagemagick
# image preview
# dependency for ueberzug
sudo dnf install libXres-devel
git clone https://github.com/ueber-devel/ueberzug.git
cd ueberzug; python setup.py install --user
```

#### Video

```sh
# video preview
sudo dnf install ffmpegthumbnailer
```

#### EPUB

```sh
# epub preview
sudo dnf install calibre
```

## Extensions

### devicon
- https://github.com/cdump/ranger-devicons2

    ```sh
    # icons
    git clone https://github.com/cdump/ranger-devicons2 ~/.config/ranger/plugins/devicons2
    ```

### disk menu
- https://github.com/SL-RU/ranger_udisk_menu

    ```sh
    # disk menu using udiskctl
    git clone https://github.com/SL-RU/ranger_udisk_menu ~/.config/ranger/plugins/ranger_udisk_mnu
    ```

### drag-and-drop function
- https://github.com/ranger/ranger/wiki/Drag-and-Drop
- https://github.com/mwh/dragon

    ```sh
    # drag-and-drop function
    git clone https://github.com/mwh/dragon.git ~/Desktop
    cd ~/Desktop/dragon; make; sudo mv dragon /usr/local/bin
    ```

### archive function (extract/compress files)
- https://github.com/maximtrp/ranger-archives

    ```sh
    cd ~/.config/ranger/plugins
    git clone https://github.com/maximtrp/ranger-archives.git
    ```

### Ranger quit on working directory wrapper (fish function)
- https://github.com/ranger/ranger/wiki/Integration-with-other-programs

    ```fish
    function ranger
        set tempfile (mktemp -t tmp.XXXXXX)
        set command_argument "map Q chain shell echo %d > $tempfile; quitall"
        set command_argument "map <C-w> chain shell echo %d > $tempfile; quitall"
        command ranger --cmd="$command_argument" $argv
        if test -s $tempfile
            set ranger_pwd (cat $tempfile)
            if test -n $ranger_pwd -a -d $ranger_pwd
                builtin cd -- $ranger_pwd
            end
        end
        command rm -f -- $tempfile
        clear
    end
    ```

- However, the fish function wrapper does __NOT__ work well with `tmux-resurrect`
- My solution is as follow (not as elegant as previous one, but at least it works with `tmux-resurrect`)
    1. Wrap quit command in `rc.conf` with save current directory path to `/tmp/tmp.ranger` before quitting
    2. Map `[Shift]+[x]` to `cd_tmp_dir` in `command.py` that changes directory to path in `/tmp/tmp.ranger`
    3. Also map `[x]` to quit for keybinding consistency that (`[Shift]`)+`[key]` should (undo)/do something
