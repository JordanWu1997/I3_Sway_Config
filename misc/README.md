# Misc Directory
Miscellaneous configuration files.

Table of Contents
=================

* [Misc Directory](#misc-directory)
* [Context](#context)
   * [browser_extensions](#browser_extensions)
      * [Vimium](#vimium)
   * [Anne_Pro_2](#anne_pro_2)
* [Reference](#reference)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# Context
File in this directory will not affect i3 environment customization.
But related to my favored workflow (i.e. keyboard-driven workflow).

## browser_extensions
- [Vimium](https://chrome.google.com/webstore/detail/vimium/dbepggeogbaibhgnhhndojpepiihcmeb), plugin to apply keyboard-driven workflow to the browser with vim-like key actions
    - `Vimium`:
        - `vimium-options.json`
            - Customized vimium keybindings
            - Vimium rule for websites

## keyboard
- [Anne_Pro_2](https://www.annepro.net/), 60% keyboard with functions to define each keys in different layers
    - `Anne_Pro_2`:
        - `Custom.json`
            - Customized keyboard profile for Anne Pro 2

## obsidian
- [Obsidian](https://obsidian.md/), brilliant markdown editor for note-taking
    - `obsidian`:
        - `obsidian`: obsidian vault dotfile directory
            - Copy this directory to obsidian vault directory and change the name to `.obsidian`
            - And then the vault settings will be applied when you next time open vault in obsidian
        - `obsidian.vimrc`
            - Configuration file for vim-plugin in obisidian

## fish
- [Fish](https://fishshell.com/), friendly interactive shell
    - `fish`:
        - `config.fish`
            - My minimal fish configuration file

## ubuntu
- [Ubuntu](https://ubuntu.com/), [Debian](https://www.debian.org/) based linux disto
    - `ubuntu`:
        - `conky`
            - conky customized configurations for my ubuntu work laptop, specific network interface, OS logos, and etc.
        - `picom`
            - picom configuration for those distros that are not available for [picom (journaburg-fork)](https://github.com/jonaburg/picom)
        - images: `*.png`
            - Supplements for `~/.config/i3/share`
        - scripts: `*.sh`
            - Supplements for `~/.config/i3/script`

# Reference
- https://chrome.google.com/webstore/detail/vimium/dbepggeogbaibhgnhhndojpepiihcmeb
- https://www.annepro.net/
- https://obsidian.md/
