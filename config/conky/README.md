# Conky_Config
My customized conky (system monitor for X) configuration files

Table of Contents
=================

* [Conky_Config](#conky_config)
* [Context](#context)
   * [Conky](#conky)
   * [Configurations](#configurations)
   * [Reference](#reference)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# Context

## Conky
- Conky is the background system monitor that shows up in the desktop
- In my customization, there are two kinds of conky:
    - `conky_config_binkey`: Display my i3 binding keys and date time
    - `conky_config_system`: Display system information (e.g. CPU usage etc.)

## Configurations

### Directory
- `full`:
    - Display all detailed information
        - `bindkey`: show all i3 binding keys
        - `system`: show all system information including processor, memory, graphics, disk, network, IP
    - CPU, GPU, network interface all need to be tweaked for new usage
- `light`:
    - Display partial information
        - `bindkey`: show partial i3 binding keys
        - `system`: show partial system information including process, memory, network, IP
    - Network interface needs to be tweaked for new usage
- `minimal`:
    - Display most important/needed information
        - `bindkey`: show most important i3 binding keys (e.g. kill window, move focus)
        - `system`: show minimal system information including processor, memory, network
    - No needs to be tweaked for new usage, works out of box for virtual machine

### Symbolic Link
- `conky_config_bindkey`
    - Symbolic link for the above configuration (full/light/minimal)
    - Linking is available in conky mode embedded within custom mode
        - Check `configs/i3/config.d/i3_custom.config`
- `conky_config_system`
    - Symbolic link for the above configuration (full/light/minimal)
    - Linking is available in conky mode embedded within custom mode
        - Check `configs/i3/config.d/i3_custom.config`

## Reference
- https://github.com/brndnmtthws/conky
- http://conky.sourceforge.net/variables.html
