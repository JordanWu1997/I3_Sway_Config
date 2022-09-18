#!/usr/bin/env bash

# Read template colors
read_template_color () {
    case $2 in
        "16")
            # Read 16-color template colors
            COLOR0=$(awk 'NR==1 {print substr($1,2,7)}' $1)
            COLOR1=$(awk 'NR==2 {print substr($1,2,7)}' $1)
            COLOR2=$(awk 'NR==3 {print substr($1,2,7)}' $1)
            COLOR3=$(awk 'NR==4 {print substr($1,2,7)}' $1)
            COLOR4=$(awk 'NR==5 {print substr($1,2,7)}' $1)
            COLOR5=$(awk 'NR==6 {print substr($1,2,7)}' $1)
            COLOR6=$(awk 'NR==7 {print substr($1,2,7)}' $1)
            COLOR7=$(awk 'NR==8 {print substr($1,2,7)}' $1)
            COLOR8=$(awk 'NR==9 {print substr($1,2,7)}' $1)
            COLOR9=$(awk 'NR==10 {print substr($1,2,7)}' $1)
            COLOR10=$(awk 'NR==11 {print substr($1,2,7)}' $1)
            COLOR11=$(awk 'NR==12 {print substr($1,2,7)}' $1)
            COLOR12=$(awk 'NR==13 {print substr($1,2,7)}' $1)
            COLOR13=$(awk 'NR==14 {print substr($1,2,7)}' $1)
            COLOR14=$(awk 'NR==15 {print substr($1,2,7)}' $1)
            COLOR15=$(awk 'NR==16 {print substr($1,2,7)}' $1)
            ;;
        "9")
            # Read 9-color template colors
            COLOR0=$(awk 'NR==1 {print substr($1,2,7)}' $1)
            COLOR1=$(awk 'NR==10 {print substr($1,2,7)}' $1)
            COLOR2=$(awk 'NR==11 {print substr($1,2,7)}' $1)
            COLOR3=$(awk 'NR==12 {print substr($1,2,7)}' $1)
            COLOR4=$(awk 'NR==13 {print substr($1,2,7)}' $1)
            COLOR5=$(awk 'NR==14 {print substr($1,2,7)}' $1)
            COLOR6=$(awk 'NR==15 {print substr($1,2,7)}' $1)
            COLOR7=$(awk 'NR==16 {print substr($1,2,7)}' $1)
            COLOR8=$(awk 'NR==9 {print substr($1,2,7)}' $1)
            COLOR9=$(awk 'NR==10 {print substr($1,2,7)}' $1)
            COLOR10=$(awk 'NR==11 {print substr($1,2,7)}' $1)
            COLOR11=$(awk 'NR==12 {print substr($1,2,7)}' $1)
            COLOR12=$(awk 'NR==13 {print substr($1,2,7)}' $1)
            COLOR13=$(awk 'NR==14 {print substr($1,2,7)}' $1)
            COLOR14=$(awk 'NR==15 {print substr($1,2,7)}' $1)
            COLOR15=$(awk 'NR==16 {print substr($1,2,7)}' $1)
            ;;
        *)
            echo "9" or "16"
    esac
}

# Generate file: colors
generate_file_color_template () {
    cp $1 "$(dirname $1)/colors"
}

# Generate file: colors-kitty.conf
add_colors_to_color_file () {
    # Copy color file template
    cp ./template/$(basename $2) $2
    # Add colors
    case $1 in
        "wrap_by_single_quote")
            sed -i "s/COLOR0$/\#$COLOR0/g" $2
            sed -i "s/COLOR1$/\#$COLOR1/g" $2
            sed -i "s/COLOR2$/\#$COLOR2/g" $2
            sed -i "s/COLOR3$/\#$COLOR3/g" $2
            sed -i "s/COLOR4$/\#$COLOR4/g" $2
            sed -i "s/COLOR5$/\#$COLOR5/g" $2
            sed -i "s/COLOR6$/\#$COLOR6/g" $2
            sed -i "s/COLOR7$/\#$COLOR7/g" $2
            sed -i "s/COLOR8$/\#$COLOR8/g" $2
            sed -i "s/COLOR9$/\#$COLOR9/g" $2
            sed -i "s/COLOR10$/\#$COLOR10/g" $2
            sed -i "s/COLOR11$/\#$COLOR11/g" $2
            sed -i "s/COLOR12$/\#$COLOR12/g" $2
            sed -i "s/COLOR13$/\#$COLOR13/g" $2
            sed -i "s/COLOR14$/\#$COLOR14/g" $2
            sed -i "s/COLOR15$/\#$COLOR15/g" $2
            ;;
        "no_wrap")
            sed -i "s/COLOR0$/\#$COLOR0/g" $2
            sed -i "s/COLOR1$/\#$COLOR1/g" $2
            sed -i "s/COLOR2$/\#$COLOR2/g" $2
            sed -i "s/COLOR3$/\#$COLOR3/g" $2
            sed -i "s/COLOR4$/\#$COLOR4/g" $2
            sed -i "s/COLOR5$/\#$COLOR5/g" $2
            sed -i "s/COLOR6$/\#$COLOR6/g" $2
            sed -i "s/COLOR7$/\#$COLOR7/g" $2
            sed -i "s/COLOR8$/\#$COLOR8/g" $2
            sed -i "s/COLOR9$/\#$COLOR9/g" $2
            sed -i "s/COLOR10$/\#$COLOR10/g" $2
            sed -i "s/COLOR11$/\#$COLOR11/g" $2
            sed -i "s/COLOR12$/\#$COLOR12/g" $2
            sed -i "s/COLOR13$/\#$COLOR13/g" $2
            sed -i "s/COLOR14$/\#$COLOR14/g" $2
            sed -i "s/COLOR15$/\#$COLOR15/g" $2
            ;;
        "end_with_semi_column")
            sed -i "s/COLOR0;$/\#$COLOR0\;/g" $2
            sed -i "s/COLOR1;$/\#$COLOR1\;/g" $2
            sed -i "s/COLOR2;$/\#$COLOR2\;/g" $2
            sed -i "s/COLOR3;$/\#$COLOR3\;/g" $2
            sed -i "s/COLOR4;$/\#$COLOR4\;/g" $2
            sed -i "s/COLOR5;$/\#$COLOR5\;/g" $2
            sed -i "s/COLOR6;$/\#$COLOR6\;/g" $2
            sed -i "s/COLOR7;$/\#$COLOR7\;/g" $2
            sed -i "s/COLOR8;$/\#$COLOR8\;/g" $2
            sed -i "s/COLOR9;$/\#$COLOR9\;/g" $2
            sed -i "s/COLOR10;$/\#$COLOR10\;/g" $2
            sed -i "s/COLOR11;$/\#$COLOR11\;/g" $2
            sed -i "s/COLOR12;$/\#$COLOR12\;/g" $2
            sed -i "s/COLOR13;$/\#$COLOR13\;/g" $2
            sed -i "s/COLOR14;$/\#$COLOR14\;/g" $2
            sed -i "s/COLOR15;$/\#$COLOR15\;/g" $2
            ;;
        "wal_json_file")
            sed -i "s/COLOR0/\#$COLOR0/g" $2
            sed -i "s/COLOR8/\#$COLOR8/g" $2
            sed -i "s/COLOR9/\#$COLOR9/g" $2
            sed -i "s/COLOR10/\#$COLOR10/g" $2
            sed -i "s/COLOR11/\#$COLOR11/g" $2
            sed -i "s/COLOR12/\#$COLOR12/g" $2
            sed -i "s/COLOR13/\#$COLOR13/g" $2
            sed -i "s/COLOR14/\#$COLOR14/g" $2
            sed -i "s/COLOR15/\#$COLOR15/g" $2
            ;;
        *)
            echo "wrap_by_single_quote", "no_wrap", "end_with_semi_column", "wal_json_file"
    esac
}

replace_wal_color_file () {
    command cp $1 $HOME/.cache/wal/
}

generate_theme_color_files () {
    # Template
    generate_file_color_template $1
    read_template_color $1 $2
    # FILE: colors.Xresources
    add_colors_to_color_file no_wrap "$(dirname $1)/colors.Xresources"
    # FILE: colors.sh
    add_colors_to_color_file wrap_by_single_quote "$(dirname $1)/colors.sh"
    # FILE: colors.json
    add_colors_to_color_file wal_json_file "$(dirname $1)/colors.json"
    # FILE: colors-kitty.conf
    add_colors_to_color_file no_wrap "$(dirname $1)/colors-kitty.conf"
    # FILE: colors-rofi-dark.rasi
    add_colors_to_color_file end_with_semi_column "$(dirname $1)/colors-rofi-dark.rasi"
}

# Main
# generate_theme_color_files [theme_color_template] [9/16] [apply_now]
if [ -z $1 ] || [ -z $2 ]; then
    echo generate_theme_color_files [theme_color_template] [9/16] [apply_now]
else
    generate_theme_color_files $1 $2 $3
    if [ $3 == "apply_now" ]; then
        replace_wal_color_file "$(dirname $1)/colors"
        replace_wal_color_file "$(dirname $1)/colors.Xresources"
        replace_wal_color_file "$(dirname $1)/colors.sh"
        replace_wal_color_file "$(dirname $1)/colors.json"
        replace_wal_color_file "$(dirname $1)/colors-kitty.conf"
        replace_wal_color_file "$(dirname $1)/colors-rofi-dark.rasi"
        # Reload Xresources
        xrdb -load ~/.Xresources
        # Reload i3
        i3-msg reload
    fi
fi
