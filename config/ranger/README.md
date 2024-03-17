# Ranger Config
My ranger configuration file and post-installation

# Context

## Configs

## Post-installation

### preview tool installation

#### PDF
```bash
# pdf preview
sudo dnf install poppler-utils pdftoppm
```

#### Text, Word, Excel, Markdown
```bash
# word/odt preview
sudo dnf install odt2txt
# excel preview
sudo dnf install catdoc
# markdown preview
sudo dnf install pandoc
```

#### HTML
```bash
# html preview
sudo dnf install w3m
```

#### Image
```bash
# image preview
sudo dnf install w3m-img imagemagick
# image preview
# dependency for ueberzug
sudo dnf install libXres-devel
git clone https://github.com/ueber-devel/ueberzug.git
cd ueberzug; python setup.py install --user
```

#### Video
```bash
# video preview
sudo dnf install ffmpegthumbnailer
```

#### EPUB
```bash
# epub preview
sudo dnf install calibre
```

## Extensions

### devicon
```bash
# icons
git clone https://github.com/cdump/ranger-devicons2 ~/.config/ranger/plugins/devicons2
```
- https://github.com/cdump/ranger-devicons2

### disk menu
```bash
# disk menu using udiskctl
git clone https://github.com/SL-RU/ranger_udisk_menu ~/.config/ranger/plugins/ranger_udisk_mnu
```
- https://github.com/SL-RU/ranger_udisk_menu

### drag-and-drop function
```bash
# drag-and-drop function
git clone https://github.com/mwh/dragon.git ~/Desktop
cd ~/Desktop/dragon; make; sudo mv dragon /usr/local/bin
```
- https://github.com/ranger/ranger/wiki/Drag-and-Drop
- https://github.com/mwh/dragon

### archive function (extract/compress files)
```bash
cd ~/.config/ranger/plugins
git clone https://github.com/maximtrp/ranger-archives.git
```
- https://github.com/maximtrp/ranger-archives

### Ranger quit on working directory wrapper
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
- https://github.com/ranger/ranger/wiki/Integration-with-other-programs
