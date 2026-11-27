# I3WM Configuration Note

Backup note for i3 configuration

# Table of Contents

- [I3WM Configuration Note](#i3wm-configuration-note)
  - [Table of Contents](#table-of-contents)
  - [Context](#context)
    - [Display configuration for X-window](#display-configuration-for-x-window)
    - [Find the i3 session from cron (DISPLAY, D-Bus)](#find-the-i3-session-from-cron-display-d-bus)
      - [Multiple i3 sessions](#multiple-i3-sessions)
    - [Monitor workspace assignment](#monitor-workspace-assignment)
    - [Lxsession agent](#lxsession-agent)
    - [Hhpc](#hhpc)
    - [Rename workspace](#rename-workspace)
    - [Dmenu](#dmenu)
    - [Master-stack layout](#master-stack-layout)
    - [Auto-name workspace](#auto-name-workspace)
    - [Xcompgr](#xcompgr)
    - [Picom](#picom)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# Context

## Bind numpad key

Binding `numpad` key in i3 needs additional settings [https://unix.stackexchange.com/questions/566566/binding-numpad-keys-on-i3-dont-work].
`Numlock` key (`Mod2` key) must be specified in every keybindings related to `numpad` key.
Also, if you want to map `shift + numpad key`, both `Mod2` and `shift` are needed in every keybindings.

- `Numpad` key in i3

  ```
  Mod2+KP_1
  Mod2+KP_2
  Mod2+KP_3
  Mod2+KP_4
  Mod2+KP_5
  Mod2+KP_6
  Mod2+KP_7
  Mod2+KP_8
  Mod2+KP_9
  Mod2+KP_0
  ```

- `Shift+Numpad` key in i3

  ```
  Mod2+Shift+KP_End
  Mod2+Shift+KP_Down
  Mod2+Shift+KP_Next
  Mod2+Shift+KP_Left
  Mod2+Shift+KP_Begin
  Mod2+Shift+KP_Right
  Mod2+Shift+KP_Home
  Mod2+Shift+KP_Up
  Mod2+Shift+KP_Prior
  Mod2+Shift+KP_Insert
  ```

## Display configuration for X-window

For now, display configuration are all integrated with my script `i3_display_operater.sh`

Set output display and primary display (use xrandr command to check) [or use arandr (GUI)]

- Xrandr label
  - --same-as for mirror mode
  - --right-of for joint mode
- General setting (arandr GUI)
  - `exec --no-startup-id arandr`
- General setting (xrandr)
  - `exec --no-startup-id xrandr --output HDMI1 --auto --primary --right-of eDP1`
- Setting for my dorm Acer27'
  - `exec --no-startup-id xrandr --output HDMI1 --mode 1920x1080 --primary --right-of eDP1`
- Setting for IOA monitor (24')
  - `exec --no-startup-id xrandr --output HDMI1 --mode 1920x1200 --primary --right-of eDP1`

Set additional display mode for monitor

- Extend mode for HDMI1 (for 16:10 1080P monitor)
  - `exec_always --no-startup-id $I3_SCRIPT/i3_display_operator.sh HDMI1 extend`
- Shrink mode for eDP1 (for better visual consistency with HDMI1)
  - `exec_always --no-startup-id $I3_SCRIPT/i3_display_operator.sh eDP1 shrink`

## Find the i3 session from cron (DISPLAY, D-Bus)

Scripts started by i3 (`exec`, keybindings) inherit the session environment. Scripts started
by cron do not: cron gives them almost nothing (`HOME`, `PATH`, `SHELL`), so

- `i3-msg` cannot find the i3 IPC socket
- `notify-send` cannot reach dunst (it needs the session D-Bus address)

Hardcoding `export DISPLAY=:1` breaks on machines where i3 runs on `:0` (or the other way
around), and `XAUTHORITY=$HOME/.Xauthority` is wrong under GDM, which keeps it in
`/run/user/<uid>/gdm/Xauthority`.

The fix is `i3_session_env.sh`: it copies the session variables from the running i3 process,
which was started with exactly the right ones. When the same user runs several i3 sessions
at once (e.g. `:1` and `:2`), `for_each_i3_session` runs the job once in each of them.

```
cron ──► script ──► for_each_i3_session [--unique-dbus] CMD
                      │ 1. pgrep -u <me> -x i3               (every i3 of this user)
                      │ 2. for each i3 PID, in its own subshell:
                      │      import_i3_session_env <pid>
                      │        a. unset DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS
                      │                 XDG_RUNTIME_DIR I3SOCK      (no leaks between sessions)
                      │        b. read /proc/<pid>/environ, export DISPLAY, XAUTHORITY,
                      │                 DBUS_SESSION_BUS_ADDRESS, XDG_RUNTIME_DIR
                      │        c. I3SOCK=$XDG_RUNTIME_DIR/i3/ipc-socket.<pid>
                      │                 (fallback: `i3 --get-socketpath` on that DISPLAY)
                      │        d. I3_SESSION_PID=<pid>
                      │      run CMD
                      │ 3. return 1 if i3 is not running or CMD failed in any session
                      ▼
          i3-msg ──► I3SOCK ──► the i3 of that session          (bar refresh)
          notify-send ──► session D-Bus ──► dunst ──► popup     (time notifier)
```

| Variable                   | Used by                  | Why                                                                        |
| -------------------------- | ------------------------ | -------------------------------------------------------------------------- |
| `DISPLAY`                  | X apps, `i3bar`          | Which X server (`:0`, `:1` ...); also identifies a session's i3bars        |
| `XAUTHORITY`               | X apps                   | Permission to talk to that X server (path differs per login manager)       |
| `I3SOCK`                   | `i3-msg`                 | IPC socket of exactly this session's i3 (see pitfall below)                |
| `DBUS_SESSION_BUS_ADDRESS` | `notify-send`            | Reaches the dunst that i3 started, which draws on i3's display             |
| `XDG_RUNTIME_DIR`          | `notify-send`, i3 socket | Fallback session bus (`/run/user/<uid>/bus`); dir of `i3/ipc-socket.<pid>` |
| `I3_SESSION_PID`           | your CMD                 | PID of the i3 the current run belongs to                                   |

Scripts using it

- `i3_bar_operator.sh refresh_with_crontab [verbose]`: restart i3bar in every i3 session
- `i3_time_notifier.sh`: show the current time (once per D-Bus bus, see `--unique-dbus`)
- `i3_automark_operator.sh refresh_with_crontab [verbose]`: restart the automark daemon in
  every i3 session
- `i3_kdeconnect_operator.sh refresh_with_crontab [verbose]`: restart `kdeconnectd` (once per
  D-Bus bus) and the pointer daemon in the sessions where it is switched on

Crontab (`crontab -e`), no environment variables needed in the line itself

```
0 * * * * /home/jordan/.config/i3/script/i3_bar_operator.sh refresh_with_crontab
0 * * * * /home/jordan/.config/i3/script/i3_automark_operator.sh refresh_with_crontab
0 * * * * /home/jordan/.config/i3/script/i3_kdeconnect_operator.sh refresh_with_crontab
*/15 * * * * /home/jordan/.config/i3/script/i3_time_notifier.sh
```

Use it in a new cron script: start from the template
`script/i3_multi_session_template.sh` (operations `list_sessions`, `run`,
`refresh_with_crontab [verbose]`, with examples for a per-session job, a daemon restart and
a notification), or by hand:

```bash
source "$(dirname "$(readlink -f "$0")")/i3_session_env.sh"

my_job () { i3-msg ...; }                 # runs with one session's DISPLAY, I3SOCK, D-Bus ...
for_each_i3_session my_job || exit 1      # every i3 session; exit 1 when i3 is not running
                                          # or my_job failed in any session
for_each_i3_session --unique-dbus notify-send Hi   # once per D-Bus bus (notifications)

# Only the newest i3 session, imported into the current shell
import_i3_session_env || exit 1
```

Process helpers (call them inside a per-session function, they use that session's `DISPLAY`)

| Helper                               | Does                                                                       |
| ------------------------------------ | -------------------------------------------------------------------------- |
| `i3_session_proc_pids PGREP_ARGS...` | PIDs matching `pgrep PGREP_ARGS` whose environment has this `DISPLAY`      |
| `i3_session_python_pids SCRIPT_NAME` | PIDs of `python* .../SCRIPT_NAME` of this session (exact argv match)       |
| `i3_session_kill LISTER [ARGS...]`   | Stop what `LISTER ARGS` prints: SIGTERM, SIGKILL after 2s, wait until gone |

```bash
restart_my_daemon () {
    i3_session_kill i3_session_python_pids my_daemon.py            # only this session's copy
    i3-msg -- exec --no-startup-id "python3 $I3_SCRIPT/my_daemon.py" >/dev/null
}
for_each_i3_session restart_my_daemon
```

### Multiple i3 sessions

Each session is handled in a subshell, so nothing one session exports reaches the next, and
a failure in one session does not stop the others.

Restarting i3bar per session (`restart_session_i3bar` in `i3_bar_operator.sh`, also used by
`bar_reload`)

```
for each i3 session (DISPLAY=:N, I3SOCK=<its socket>)
  1. PIDs = this user's i3bar whose /proc/<pid>/environ has DISPLAY=:N
  2. kill PIDs (SIGTERM), wait up to 2s; still alive ──► SIGKILL
  3. i3-msg exec 'i3bar -b bar_status'   ──► started by that session's i3
     i3-msg exec 'i3bar -b bar_mode'
```

- `killall i3bar` is not used: it kills the bars of every session, so restarting session 2
  would kill the bars just restarted in session 1
- The old bars are gone before new ones start, so a bar never runs twice on one display
- The automark and kdeconnect pointer daemons are restarted the same way, through
  `i3_session_kill i3_session_python_pids <script>.py` and `i3-msg exec`

Rules for scripts that act on several sessions

- No `killall X` / `pkill X` for per-session programs: it hits every session
- No plain `pgrep -f name.py` to find a daemon: it also matches `vim name.py` or a shell whose
  command line contains the name (this killed a test shell during development);
  use `i3_session_python_pids`
- Start long-running programs with `i3-msg exec`: they then belong to that session's i3, and
  the cron job neither blocks on them nor takes them down when it exits
- Per-user D-Bus services (`kdeconnectd`, notifications) exist once per bus, not per session:
  use `--unique-dbus`

Pitfall: `I3SOCK` wins over `DISPLAY`

`i3-msg` uses `$I3SOCK` first and only falls back to the X display when it is unset. Every
terminal inside i3 has `I3SOCK` set to that session's socket. Without step 2a/2c above,
running `refresh_with_crontab` from a terminal sent the `exec i3bar` of *every* session to
the i3 of that terminal, which then showed duplicated bars. Each session now gets its own
`I3SOCK` explicitly, so running the scripts from cron or from any terminal behaves the same.

Notifications and the shared D-Bus

Sessions of one user usually share the systemd user bus (`/run/user/<uid>/bus`). Only one
notification daemon can own `org.freedesktop.Notifications` on it, so every notification shows
in the dunst that registered first, on that session's display only. `--unique-dbus` sends the
notification once per distinct bus, so it is not shown twice there. To get notifications on
every display, each session needs its own bus (e.g. start i3 with `dbus-run-session i3`).

Troubleshooting

- List the i3 sessions: `for p in $(pgrep -x i3); do echo "$p $(tr '\0' '\n' </proc/$p/environ | grep -E '^(DISPLAY|DBUS_SESSION_BUS_ADDRESS)=' | xargs)"; done`
- List the i3bars and the session they belong to:
  `for p in $(pgrep -x i3bar); do echo "$p $(tr '\0' '\n' </proc/$p/environ | grep -E '^(DISPLAY|I3SOCK)=' | xargs) $(tr '\0' ' ' </proc/$p/cmdline)"; done`
  (each `DISPLAY` should show exactly one `bar_status` and one `bar_mode`)
- See what each session gets: `bash -c 'source ~/.config/i3/script/i3_session_env.sh; for_each_i3_session bash -c "echo \$I3_SESSION_PID \$DISPLAY \$I3SOCK"'`
- Run a cron job the way cron does: `env -i HOME=$HOME PATH=/usr/bin:/bin /home/jordan/.config/i3/script/i3_time_notifier.sh`
- See cron's own errors: `grep CRON /var/log/syslog` (Ubuntu) or `journalctl -u cron` / `journalctl -u crond` (Fedora)

Limitations

- Nothing runs while i3 is not running: the scripts print `i3 is not running for this user` and exit 1
- A session whose IPC socket cannot be found prints `Cannot find the IPC socket of i3 (PID <pid>)`
  and is skipped (the script then exits 1); the other sessions are still handled
- Notifications show on one display only while the sessions share a D-Bus bus (see above)

## Monitor workspace assignment

Assign each block of 10 workspaces to one monitor (A: ws 1~10, B: ws 11~20, C: ws 21~30, D: ws 31~40).
REMOVED because I use different monitor setups and want workspaces to open on the monitor I focus on.
If the assigned monitor does not exist, the workspace just spawns on the current monitor.

- Pros
  - The workspace number tells which monitor it is on
  - When a monitor is plugged back in, i3 moves its assigned workspaces back to it
- Cons
  - Output names depend on the X driver (Intel DDX: `HDMI1`, `eDP1`; modesetting: `HDMI-1`, `eDP-1`),
    and a wrong name makes the assignment silently do nothing
  - `VIRTUAL1`/`VIRTUAL2` only exist with the Intel driver
  - Does not fit setups that change often

- Monitor variables in `config` (set monitor order according to frequent-usage priority)

  ```
  # Set monitor order according to frequent-usage priority
  # If the monitor does not exist, workspaces will just spawn in current monitor
  set $monitor1 HDMI1
  set $monitor2 eDP1
  set $monitor3 VIRTUAL1
  set $monitor4 VIRTUAL2
  ```

- Workspace assignment in `config.d/i3_workspace.config`

  ```
  # Assign workspace for quadra monitor (monitor1 + monitor2 + monitor3 + monitor4)
  # monitor 1 (ws 1~10)
  workspace $ws1  output $monitor1
  workspace $ws2  output $monitor1
  workspace $ws3  output $monitor1
  workspace $ws4  output $monitor1
  workspace $ws5  output $monitor1
  workspace $ws6  output $monitor1
  workspace $ws7  output $monitor1
  workspace $ws8  output $monitor1
  workspace $ws9  output $monitor1
  workspace $ws10 output $monitor1
  # monitor 2 (ws 11~20)
  workspace $ws11 output $monitor2
  workspace $ws12 output $monitor2
  workspace $ws13 output $monitor2
  workspace $ws14 output $monitor2
  workspace $ws15 output $monitor2
  workspace $ws16 output $monitor2
  workspace $ws17 output $monitor2
  workspace $ws18 output $monitor2
  workspace $ws19 output $monitor2
  workspace $ws20 output $monitor2
  # monitor 3 (ws 21~30)
  workspace $ws21 output $monitor3
  workspace $ws22 output $monitor3
  workspace $ws23 output $monitor3
  workspace $ws24 output $monitor3
  workspace $ws25 output $monitor3
  workspace $ws26 output $monitor3
  workspace $ws27 output $monitor3
  workspace $ws28 output $monitor3
  workspace $ws29 output $monitor3
  workspace $ws30 output $monitor3
  # monitor 4 (ws 31~40)
  workspace $ws31 output $monitor4
  workspace $ws32 output $monitor4
  workspace $ws33 output $monitor4
  workspace $ws34 output $monitor4
  workspace $ws35 output $monitor4
  workspace $ws36 output $monitor4
  workspace $ws37 output $monitor4
  workspace $ws38 output $monitor4
  workspace $ws39 output $monitor4
  workspace $ws40 output $monitor4
  ```

- Tip: i3 (>= 4.16) accepts a fallback list of outputs, which covers both driver namings
  - `workspace $ws1 output HDMI1 HDMI-1 primary`

## Lxsession agent

Load xsession initialization.
For now, this agent will cause mouse left/right button reversed

- Run in i3
  - `exec --no-startup-id lxsession`

## Hhpc

Hide cursor when idle [https://github.com/Aktau/hhpc].
For Fedora, hhpc needs to be complied from source manually.
In i3, hhps conflicts with i3lock since there is no cursor to lock

- Run in i3
  - `exec_always --no-startup-id hhpc -i 3`

## Rename workspace

Rename i3 workspace.
This function conflicts with auto-rename workspace function

- Here use i3-input as input for i3
  - `bindsym Mod4+Shift+w exec i3-input -F "rename workspace to %s" -l 1 -P "New workspace name: "`
- Here use rofi as input for i3
  - `bindsym Mod4+Shift+w exec i3-msg rename workspace to $(rofi -dmenu -lines 0 -width 25 -p "Rename Workspace")`

## Dmenu

Dmenu is i3 built-in selection menu for applications, programs, and etc.
For Fedora, installation: `dnf install dmenu`
There also is the (new) i3-dmenu-desktop which only displays applications
shipping a .desktop file. It is a wrapper around dmenu, so you need dmenu installed.

- Run dmenu (application launcher) in i3

  ```
  bindsym Mod4+Shift+Return exec --no-startup-id dmenu_run -l 16 \
    -fn "DroidSansMono Nerd Font 16" -p "Dmenu [Program Launcher]" \
    -nb "$bg" -nf "$c1" -sb "$c3" -sf "$fg"
  ```

- Run i3-dmenu-desktop in i3

  ```
  bindsym Mod4+Shift+Return exec --no-startup-id i3-dmenu-desktop \
    --dmenu="dmenu -fn 'pango:DroidSansMono Nerd Font 16' -l 10 -p 'Program launcher'"
  ```

## I3-lock

- I3 lock mode with I3-lock

  ```
  # Lock mode (i3lock)
  bindsym Ctrl+Mod1+Shift+l mode "i3lock: Return to lock/Escape to Cancel"
  mode "i3lock: Return to lock/Escape to Cancel" {
      # Option1 - User defined wallpaper
      # use default wallpaper is assigned wallpaper directory does not exist
      #bindsym Return exec --no-startup-id i3lock -t -f -i \
          #$([ -d "$WALLPAPER8" ] && echo $(find $WALLPAPER8 -name '*.png' | shuf -n1) || \
          #echo "$HOME/.config/i3/share/default_i3_wallpaper.png"); mode "default"
      # Option2 - Current default wallpaper (Must be PNG format, or use default wallpaper)
      bindsym Return exec --no-startup-id $I3_SCRIPT/i3_i3lock_operator.sh current; mode "default"
      # exit mode
      bindsym Escape mode "default"
  }
  ```

## Master-stack layout

Add master-stack layout to i3 [https://github.com/windwp/i3-master-stack]
The master-stack mode conflicts with both i3_automark.py, autotiling.
They must be DISABLED first.

- Installation
  - `cd ~/.config/i3/; git clone https://github.com/windwp/i3-master-stack.git`
- Run in i3
  - `exec_always --no-startup-id $HOME/.config/i3/i3-master-stack/i3_master`

Master-stack layout keybindings

- Swap to master node
  - `bindsym Mod4+semicolon nop swap master`
- Go to master node
  - `bindsym Mod4+m nop go master`
- Enable/disable master layout in current workspace
  - `bindsym $mod+alt+m nop master toggle`

## Auto-name workspace

Auto-name workspace name with fancy symbols [https://github.com/cboddy/i3-workspace-names-daemon].
For fancy symbols support, NERD font must be installed first.
Symbols can be user-defined in `$HOME/.config/i3/share/app-icons.json`.

- Run in i3
  - `exec --no-startup-id i3-workspace-names-daemon -config-path $HOME/.config/i3/share/app-icons.json`

## Xcompgr

X-window compositor for transparency support (now use picom instead)
But it works better in low-resource computer (e.g virtual machine)

- Run in i3
  - `exec --no-startup-id xcompmgr -c -f -n`

## Picom

X window compositor for animation, transparency, blur support [https://man.archlinux.org/man/picom.1.en].
For now, picom function has been integrated in my `$HOME/.config/i3/script/i3_display_operator.sh script)`.
Unfortunately, picom in Fedora repository not work well [https://github.com/yshui/picom],
so I use picom fork of jonaburg [https://github.com/jonaburg/picom] instead (need manually installed on Fedora)

- Run in i3
  - `exec_always --no-startup-id /usr/local/bin/picom --config $HOME/.config/picom/picom_blur.conf`

## I3-msg

- Execute command in i3 using i3-msg with rofi as input
  - `bindsym Mod4+Shift+i exec i3-msg $(rofi -dmenu -lines 0 -p "i3 command (i3-msg)")`
