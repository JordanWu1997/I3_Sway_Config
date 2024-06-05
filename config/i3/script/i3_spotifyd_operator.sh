#!/usr/bin/env bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_spotifyd_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [playing]: show current playing"
    echo "  [status]: show current spotifyd status"
    echo "  [enable]: enable spotifyd"
    echo "  [disable]: disable spotifyd"
    echo "  [reload]: reload spotifyd"
    echo "  [attach]: attach spotifyd to spt"
    echo "  [reload_and_attach]: reload spotifyd and attach it to spt"
    echo "  [enable_track_repeat]: enable track repeat with spt"
    echo "  [disable_track_repat]: disable track repeat with spt"
}

spotifyd_operation () {
    ICON="$HOME/.config/i3/share/64x64/spotify.png"
    NOTIFY_ID=70920199
    case $1 in
        "status")
            if [[ -n $(pgrep -f ^spotifyd) ]]; then
                notify-send "Spotifyd" "Spotifyd is active" --icon=${ICON}
            else
                notify-send "Spotifyd" "Spotifyd is not active" --icon=${ICON}
            fi
            ;;
        "playing")
            PODCAST=$(spt playback --device 'spotifyd' --format "%h")
            if [[ $PODCAST == 'None' ]]; then
                PLAYING=$(spt playback --device 'spotifyd' --format "Title: %t\nArtist: %a\nAlbum: %a")
            else
                PLAYING=$(spt playback --device 'spotifyd' --format "Title: %t\nPublisher: %a\nPodcast: %h")
            fi
            notify-send -u low -r ${NOTIFY_ID} "Spotifyd" "${PLAYING}" --icon="${ICON}"
            ;;
        "enable")
            spotifyd
            notify-send "Spotifyd" "Spotifyd is enabled" --icon=${ICON}
            ;;
        "disable")
            killall spotifyd
            notify-send "Spotifyd" "Spotifyd is disabled" --icon=${ICON}
            ;;
        "attach")
            spt playback --transfer spotifyd
            notify-send "Spotifyd" "Spotifyd is attatched to spt" --icon=${ICON}
            ;;
        "reload")
            killall spotifyd
            spotifyd
            notify-send "Spotifyd" "Spotifyd is reloaded" --icon=${ICON}
            ;;
        "reload_and_attach")
            killall spotifyd
            spotifyd
            sleep 1.5
            spt playback --transfer spotifyd
            notify-send "Spotifyd" "Spotifyd is reloaded and attached to spt" --icon=${ICON}
            ;;
        "enable_track_repeat")
            ps -aux | grep "bash ${I3_SCRIPT}/i3_spt_track_repeat.sh" | \
                awk 'NR==1 {print $2}' | xargs -I {} kill {}
            notify-send -u "low" "Spotifyd" "Track repeat is enabled" --icon=${ICON}
            i3_spt_track_repeat.sh
            ;;
        "disable_track_repeat")
            notify-send -u "low" "Spotifyd" "Track repeat is disabled" --icon=${ICON}
            ps -aux | grep "bash ${I3_SCRIPT}/i3_spt_track_repeat.sh" | \
                awk 'NR==1 {print $2}' | xargs -I {} kill {}
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac

}

# Main
spotifyd_operation $1
