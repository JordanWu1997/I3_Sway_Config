# I3_Config
My I3WM configuration files

Table of Contents
=================

* [I3_Config](#i3_config)
* [Context](#context)
   * [config.d](#config.d)
   * [doc](#doc)
   * [script](#script)
   * [share](#share)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# Context
Contents in this configuration directory

## config.d
Directory of my i3 configuration files.
After i3 version 4.20, configuration include function is available.
Breaking original long configuration into sections tries to keep configuration clean.
This directory contains all sections that be included in `config` file.

- `i3_bar.config`: i3-bar configuration,
- `i3_bindkey.config`: i3-bindkey
- `i3_custom.config`: user-defined customization in i3
- `i3_gap.config`: i3 gap configuration (i3-gap has been merged to i3 in i3 v4.22)
- `i3_mode.config`: mode in i3
- `i3_startup.config`: startup programs in i3
- `i3_window.config`: settings for window/container in i3
- `i3_workspace.config`: settings for workspace in i3
- `i3_workspace_name.config`: settings for workspace name in i3 (must be included before `i3_workspace.config`)

## doc
Document problems I met in customization of i3wm, backup configurations and some notes

## script
Scripts for i3wm working environment customized for my favored workflow

## share
Files for other programs (e.g. wallpapers, auto-mark-list, app-icons)

## theme
Files and scripts for theme templates
