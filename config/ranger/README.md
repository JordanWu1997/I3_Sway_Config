# Ranger Config
My ranger configuration file and post-installation

# Context

## Configs

## Post-installation

### preview tool installation

#### PDF
```bash
# pdf preview
sudo dnf install gcc-c++ pkgconfig poppler-cpp-devel python3-devel
pip install pdftotext
```

#### ODT
```bash
# odt preview
sudo dnf install odt2txt
```

#### HTML
```bash
# html preview
sudo dnf install w3m
```

## Extensions

### devicon
```bash
# icons
git clone https://github.com/cdump/ranger-devicons2 ~/.config/ranger/plugins/devicons2
```
