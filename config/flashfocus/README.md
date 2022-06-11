# Picom_Config
My customized flashfocus (focus visualized-warning) configuration files

Table of Contents
=================

* [Picom_Config](#picom_config)
* [Context](#context)
   * [Flashfocus](#flashfocus)
   * [Configurations](#configurations)
   * [Reference](#reference)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# Context

## Flashfocus
- Flashfocus shows visualized-warning when focus changes by changing opacity of window
- Flashfocus needs picom or other compositor to change opacity of window
- Additional settings in picom is needed, check reference quick start section for details

## Configurations
- `flashfocus_blur.yml`
    - Default opacity: 0.85
    - Flash_opacity: 0.25
- `flashfocus_transparency.yml`
    - Default opacity: 1.0
    - Flash_opacity:  0.4
- `flashfocus_opaque.yml`
    - Default opacity: 0.9
    - Flash_opacity: 0.3
- `flashfocus.yml`
    - Symbolic link of the above configurations (blur/transparency/opaque)
    - Linking is available in flashfocus mode embedded within custom mode
        - Check `configs/i3/configs/i3_custom.config`

## Reference
- https://github.com/fennerm/flashfocus
