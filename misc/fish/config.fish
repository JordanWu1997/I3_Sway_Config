# ~/.config/fish/config.fish
# ============================================================================
# Dotfile information (fish configuration)
# ============================================================================
# SHELL: fish, version 3.3.1

# ============================================================================
# Profile Init (Enviroments)
# ============================================================================

# Force to refresh enviroment everytime shell is opened
source ~/.profile

# Remove duplicate path variables
# -- https://unix.stackexchange.com/questions/40749/remove-duplicate-path-entries\
# -with-awk-command/149054#149054
export PATH=(perl -e 'print join(":", grep { not $seen{$_}++ } split(/:/, $ENV{PATH}))')

# ============================================================================
# Alias Init
# ============================================================================

source ~/.bash_aliases

# ============================================================================
# Fish-only Alias Init
# ============================================================================

alias if_fish_login_shell='status --is-login; and echo yes; or echo no'
alias if_fish_interactive_shell='status --is-interactive; and echo yes; or echo no'
alias zkill="kill (ps aux | fzf | awk '{print $2}')"

# ============================================================================
# Fish Prompt Init
# ============================================================================

# Disable Fish Vi-mode
set -U fish_key_bindings fish_default_key_bindings
# Enable Fish Vi-mode
#set -U fish_key_bindings fish_vi_key_bindings

# Prompt [Now use starship instead]
#source ~/Desktop/Linux_Shell_Files/Fedora_Dotfiles/fish_prompt.fish

# ============================================================================
# Shell Setting
# ============================================================================

# Preferred editor for local and remote sessions
# Set VIM as system editor
export EDITOR=/usr/bin/nvim
export VISUAL=/usr/bin/nvim

# Gnome keyring
if test -n "$DESKTOP_SESSION"
    set -x (gnome-keyring-daemon --start | string split "="); clear
end

# ============================================================================
# My Functions
# ============================================================================

# Update tmux display (e.g. localhost:XX -> localhost:XX)
function tmux_update_display
    set LAST_DISPLAY $DISPLAY
    set DISPLAY (tmux show-env | sed -n 's/^DISPLAY=//p')
    echo "UPDATE_TMUX_DISPLAY: $LAST_DISPLAY (OLD) -> $DISPLAY (NEW)"
end

# BASH !!
function bind_bang
    switch (commandline -t)[-1]
        case "!"
            commandline -t -- $history[1]
            commandline -f repaint
        case "*"
            commandline -i !
    end
end

# BASH !$
function bind_dollar
    switch (commandline -t)[-1]
        case "!"
            commandline -f backward-delete-char history-token-search-backward
        case "*"
            commandline -i '$'
    end
end

# ============================================================================
# My Keybindings
# ============================================================================

## Fish vi-mode keybinding (alt+j)
#bind \ej fish_vi_key_bindings

## Fish default keybinding (alt+k)
#bind \ek fish_default_key_bindings

# User-defined Keybindings
function fish_user_key_bindings
    fzf_key_bindings
    bind ! bind_bang
    bind '$' bind_dollar
end

# ============================================================================
# Startup Command
# ============================================================================

# Starship
command -v starship | starship init fish | source

# Update TMUX port automatically
if set -q TMUX
    tmux_update_display
end
