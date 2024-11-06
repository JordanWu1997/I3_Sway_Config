# Script for I3WM
Script for I3WM function support
- Source code from
    - https://github.com/lincheney/i3-automark/blob/master/i3-automark.py (I rename it to `i3_automark_daemon.py` and create a simplified version called `i3_automark.py`)
        - Add more preset marks
        - Make window mark refresh when focus is change
        - Change mark option from `--replace` to `--add` to prevent mark overwriting
        - Add last window mark `'`
    - https://www.reddit.com/r/bspwm/comments/d08bzz/dunst_pywal/ (i3_dunst_walcolor.sh)
        - Not work well in dunst version > = 1.7, I rewrite one instead
        - Rename to i3_dunst_operator to integrate more dunst related operations
    - https://github.com/rjekker/i3-battery-popup (i3_battery-popup.sh)
    - https://git.bune.city/petra-fied/viscolourchanger (i3_viscolorchanger.sh)
    - https://www.youtube.com/watch?v=ulunAkEW9XU&t=636s (i3_notify_logger.sh)
    - https://aduros.com/blog/hacking-i3-window-promoting/ (i3_swap_master_window.py)
