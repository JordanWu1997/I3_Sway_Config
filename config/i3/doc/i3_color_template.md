# I3WM Color Template
- Online color palette https://thomashunter.name/i3-configurator/

Table of Contents
=================

* [I3WM Color Template](#i3wm-color-template)
   * [Table of Contents](#table-of-contents)
   * [Context](#context)
      * [Monochrome vs Non-monochrome](#monochrome-vs-non-monochrome)
      * [I3BAR](#i3bar)
         * [Default theme with minor modified](#default-theme-with-minor-modified)
         * [Monochrome color style (red -&gt; blue, low -&gt; high)](#monochrome-color-style-r ed---blue-low---high)
         * [Non-monochrome color style (red - blue, high -&gt; low)](#non-monochrome-color-sty le-red---blue-high---low)
      * [I3CONTAINTER](#i3containter)
         * [Gruvbox theme](#gruvbox-theme)
         * [Default theme with minor change](#default-theme-with-minor-change)
         * [Monochrome color style (red -&gt; blue, low -&gt; high)](#monochrome-color-style-r ed---blue-low---high-1)
         * [Non-monochrome color style (red - blue, high -&gt; low)](#non-monochrome-color-sty le-red---blue-high---low-1)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# Context

## Monochrome vs Non-monochrome
When wallpaper/color style is monochrome, new remapped color would not change much, but
it will be remap from warm color to cold color as colorfulness increases. For example,
for a orange color tone wallpaper, new red will be grayish orange as new blue will be
whitish orange. The new color temperature to human eye is totally reversed to our daily
experience. This will cause issue when apply monochrome template to non-monochrome color
wallpaper/style which is remapped based on color temperature. Here I prepare two set
of color scheme (one for monochrome, one for non-monochrome) to solve this unavoidable
problem for pywal color.

## I3BAR

### Default theme with minor modified

```
background #161821
statusline #FFFFFF
separator  #666666
# item             border   backgr. text
focused_workspace  #4C7899  #285577 #FFFFFF
active_workspace   #333333  #222222 #FFFFFF
inactive_workspace #333333  #222222 #888888
urgent_workspace   #2F343A  #900000 #FFFFFF
binding_mode       #161821  #161821 #FFFFFF
```

### Monochrome color style (red -> blue, low -> high)

```
background $bg
statusline $fg
separator  $bg
# item             border   backgr. text
focused_workspace  $c5       $c11      $c15
active_workspace   $c5       $c3       $c0
inactive_workspace $c5       $c3       $c0
urgent_workspace   $c1       $c15      $c0
binding_mode       $bg       $bg       $fg
```

### Non-monochrome color style (red - blue, high -> low)

```
background $bg
statusline $fg
separator  $bg
# item             border   backgr. text
focused_workspace  $c5       $c3       $c0
active_workspace   $c5       $c13      $c15
inactive_workspace $c5       $c13      $c15
urgent_workspace   $c1       $c15      $c0
binding_mode       $bg       $bg       $fg
```

## I3CONTAINTER

### Gruvbox theme

```
# class                 border  backgr. text    indic.  child_border
client.focused          #665c54 #665c54 #eddbb2 #2e9ef4 #665c54
client.focused_inactive #282828 #5f676a #ffffff #484e50 #5f676a
client.unfocused        #3c3836 #3c3836 #a89984 #292d2e #222222
client.urgent           #cc241d #cc241d #ebdbb2 #cc241d #cc241d
client.placeholder      #000000 #0c0c0c #ffffff #000000 #0c0c0c
client.background       #ffffff
```

### Default theme with minor change

```
# class                 border  backgr. text    indic.  child_border
client.focused          #4c7899 #285577 #ffffff #2e9ef4 #285577
client.focused_inactive #333333 #5f676a #ffffff #484e50 #5f676a
client.unfocused        #333333 #222222 #888888 #292d2e #222222
client.urgent           #2f343a #900000 #ffffff #900000 #900000
client.placeholder      #000000 #0c0c0c #ffffff #000000 #0c0c0c
client.background       #ffffff
```

### Monochrome color style (red -> blue, low -> high)

```
# class                 border  backgr. text    indic.  child_border
client.focused          $c13    $c13    $c15    $c14    $c13
client.focused_inactive $c1     $c1     $c15    $c2     $c1
client.unfocused        $c1     $c1     $c15    $c2     $c1
client.urgent           $c15    $c15    $c0     $c2     $c15
client.placeholder      $c2     $c2     $c15    $c2     $c2
client.background               $c0
```

### Non-monochrome color style (red - bue, high -> low)

```
# class                 border  backgr. text    indic.  child_border
client.focused          $c1     $c1     $c0     $c14    $c1
client.focused_inactive $c13    $c13    $c15    $c2     $c13
client.unfocused        $c13    $c13    $c15    $c2     $c13
client.urgent           $c15    $c15    $c0     $c2     $c15
client.placeholder      $c2     $c2     $c15    $c2     $c2
client.background               $c0
```
