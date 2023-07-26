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
