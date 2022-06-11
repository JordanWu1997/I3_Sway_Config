# Picom_Config
My customized picom (compositor for X) configuration files

Table of Contents
=================

* [Picom_Config](#picom_config)
* [Context](#context)
   * [Picom](#picom)
   * [Configurations](#configurations)
   * [Reference](#reference)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# Context

## Picom
- Picom is the compositor for X
- Picom fork in this configuration
    - `jonaburg`: Better support kawase blur, shadow, and animation

## Configurations
- `picom_blur.conf`
    - Picom with __kawase blur__ (experimental backend `glx` must be enabled)
        - If `glx` not works well, try `xrender` instead
- `picom_transparency.conf`
    - Picom with __transparency__ (works for both `glx` and `xrender` backend)
- `picom.conf`
    - Symbolic link of the above configurations (blur/transparency)
    - Linking is available in picom mode embedded within custom mode
        - Check `configs/i3/configs/i3_custom.config`

## Reference
- https://github.com/jonaburg/picom
