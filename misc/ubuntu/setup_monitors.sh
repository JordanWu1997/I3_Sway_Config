#!/usr/bin/env bash

add_new_mode_to_HDMI1 () {
    xrandr --newmode "1920x1200_50.00"  158.08  1920 2032 2240 2560  1200 1201 1204 1235  -HSync +Vsync
    xrandr --addmode HDMI-1 "1920x1200_50.00"
}

joint_eDP1_office_HDMI1 () {
    xrandr \
        --output eDP-1 --primary --mode 1600x900 --pos 1080x1020 --rotate normal \
        --output HDMI-1 --mode 1920x1080 --pos 0x0 --rotate left \
        --output DP-1 --off --output DP-2 --off --output DP-3 --off
}

joint_eDP1_office_DP3_HDMI1 () {
    xrandr \
        --output eDP-1 --mode 1368x768 --pos 0x1152 --rotate normal \
        --output HDMI-1 --mode 1920x1080 --pos 3288x0 --rotate left \
        --output DP-3 --primary --mode 1920x1080 --pos 1368x420 --rotate normal \
        --output DP-1 --off --output DP-2 --off
}

joint_eDP1_office_HDMI1_DP3 () {
    #xrandr \
        #--output eDP-1 --mode 1368x768 --pos 0x312 --rotate normal \
        #--output HDMI-1 --primary --mode 1920x1080 --pos 1368x0 --rotate normal \
        #--output DP-1 --off --output DP-2 --off \
        #--output DP-3 --mode 1920x1080 --pos 3288x0 --rotate left \
        #--output VIRTUAL-1 --off
    xrandr \
        --output eDP-1 --mode 1368x768 --pos 0x1152 --rotate normal \
        --output HDMI-1 --primary --mode 1920x1080 --pos 1368x420 --rotate normal \
        --output DP-1 --off --output DP-2 --off \
        --output DP-3 --mode 1920x1080 --pos 3288x0 --rotate left
}

joint_eDP1_home_HDMI1 () {
    add_new_mode_to_HDMI1
    xrandr \
        --output eDP-1 --mode 1368x768 --pos 1920x432 --rotate normal \
        --output HDMI-1 --primary --mode 1920x1200_50.00 --pos 0x0 --rotate normal \
        --output DP-1 --off --output DP-2 --off --output DP-3 --off
}

start_eDP1_only () {
    xrandr \
        --output eDP-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal \
        --output HDMI-1 --off \
        --output DP-1 --off --output DP-2 --off --output DP-3 --off
}

# Auto setup for joint eDP1 and HDMI1
auto_setup () {
    eDP1_STATUS=$(xrandr | awk '$1~/^eDP-1/{print $2}')
    HDMI1_STATUS=$(xrandr | awk '$1~/^HDMI-1/ {print $2}')
    DP1_STATUS=$(xrandr | awk '$1~/^DP-1/ {print $2}')
    DP2_STATUS=$(xrandr | awk '$1~/^DP-2/ {print $2}')
    DP3_STATUS=$(xrandr | awk '$1~/^DP-3/ {print $2}')

    echo ===============
    echo DISPLAY: STATUS
    echo ===============
    echo eDP1:${eDP1_STATUS}
    echo HDMI1:${HDMI1_STATUS}
    echo DP1:${DP1_STATUS}
    echo DP2:${DP2_STATUS}
    echo DP3:${DP3_STATUS}

    case ${HDMI1_STATUS}_${eDP1_STATUS} in
        # Both eDP1-1 and HDMI-1 are connected
        'connected_connected')
            case $1 in
                'office')
                    #joint_eDP1_office_HDMI1_DP3
                    joint_eDP1_office_DP3_HDMI1
                    ;;
                'home')
                    joint_eDP1_home_HDMI1
                    ;;
            esac
            ;;
        # Only eDP-1 is connected
        'disconnected_connected')
            start_eDP1_only
    esac
}

# Main
if [[ $1 == 'auto_in_office' ]]; then
    auto_setup office
elif [[ $1 == 'auto_at_home' ]]; then
    auto_setup home
else
    select monitor_option in \
        'auto_joint_in_office' \
        'auto_joint_at_home' \
        'eDP1_only' \
        'HDMI1_only' \
        'eDP1_HDMI1_mirror'
    do
        case ${monitor_option} in
            'eDP1_only')
                xrandr \
                    --output eDP-1 --primary --mode 1600x900 --pos 0x0 --rotate normal \
                    --output HDMI-1 --off \
                    --output DP-1 --off --output DP-2 --off --output DP-3 --off
                break
                ;;
            'HDMI1_only')
                xrandr \
                    --output eDP-1 --off \
                    --output HDMI-1 --mode 1920x1080 --pos 0x0 --rotate normal \
                    --output DP-1 --off --output DP-2 --off --output DP-3 --off
                break
                ;;
            'eDP1_HDMI1_mirror')
                xrandr \
                    --output eDP-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal \
                    --output HDMI-1 --mode 1920x1080 --pos 0x0 --rotate normal \
                    --output DP-1 --off --output DP-2 --off --output DP-3 --off
                break
                ;;
            'auto_joint_in_office')
                auto_setup office
                break
                ;;
            'auto_joint_at_home')
                auto_setup home
                break
        esac
    done
fi
