# I3WM Program Note
Backup note for programs for working environment

Table of Contents
=================

* [I3WM Program Note](#i3wm-program-note)
* [Context](#context)
   * [Rofi](#rofi)
   * [Dunst](#dunst)
   * [Picom](#picom)
   * [Neovim](#neovim)
   * [I3 Additional Tools](#i3-additional-tools)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# Context

## Rofi

Dependency for compiling [rofi](https://github.com/davatorium/rofi) version 1.6.1

```sh
dnf install bison flex libxcb libxcbcommon libxcbcommon-X11 libxkbcommon-x11 \
    libxkbcommon libxkbcommon-utils libxkbcommon-devel libxkbcommon-x11-devel \
    xcb-util-wm xcb-util-wm-devel xcb-util-devel xcb-util-xrm-devel pango-devel \
    startup-notification-devel gdk-pixbuf2-devel check-devel
```

## Dunst

Dependency for compilng [dunst](https://github.com/davatorium/rofi) 1.6.1 (ONLY compile for Xorg)

```sh
dnf install dbus dbus-devel libXinerama-devel libXrandr-devel libXScrnSaver-devel \
    libnotify-devel libwayland-client-devel libwayland-client
```

## Picom

Dependency for compiling [picom jonaburg fork](https://github.com/jonaburg/picom)

```sh
dnf install libev-devel xcb-util-renderutil-devel xcb-util-image-devel.x86_64 \
    uthash-devel libconfig-devel
```

## Neovim

Python packages for python coding in neovim

```sh
python -m pip install pynvim ipdb jedi
```

## I3 Additional Tools

Useful additional tools fro i3 working environment

```
python -m pip install flashfocus  autotiling automark pywal
```