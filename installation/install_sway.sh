#!/usr/bin/env bash
# ============================================================================
# This shell script installs my sway (Wayland) work environment on top of the
# i3 environment (run install_apt_ubuntu_2404_LTS.sh / install_dnf.sh first for
# the shared tools: kitty, fish, rofi themes, dunst, pywal, bumblebee-status ...).
#
# Supported: Ubuntu 24.04+/Pop!_OS 24.04+ (apt), Fedora 40+ (dnf).
# Ubuntu/Pop!_OS 22.04 ships sway 1.7, which lacks bindgesture, smart_gaps
# inverse_outer and input-method popups used by this config -> upgrade first.
#
# Every item of i3 -> sway package mapping is explained in
# config/sway/doc/05_PACKAGES_AND_INSTALL.md
# ============================================================================

set -u
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NEW_CONFIG_DIR="${REPO_DIR}/config"
USER_CONFIG_DIR="$HOME/.config"
BUILD_DIR="$HOME/Desktop/sway_build"

# ----------------------------------------------------------------------------
# Section 1 - Detect distribution / package manager
# ----------------------------------------------------------------------------
. /etc/os-release
if command -v apt >/dev/null 2>&1; then
    PM=apt
elif command -v dnf >/dev/null 2>&1; then
    PM=dnf
else
    echo "Unsupported distribution (need apt or dnf)"; exit 1
fi
echo "Detected ${PRETTY_NAME} (package manager: ${PM})"

if [ "${PM}" = apt ] && [ "${VERSION_ID%%.*}" -lt 24 ] 2>/dev/null; then
    echo "WARNING: ${PRETTY_NAME} provides sway 1.7. This configuration needs sway >= 1.9"
    echo "         (bindgesture, smart_gaps inverse_outer, IME popups need >= 1.10)."
    echo "         Upgrade to 24.04+ or build sway/wlroots from source before continuing."
    read -r -p "Continue anyway? [y/N] " answer
    [ "${answer}" = y ] || exit 1
fi

# pkg <apt names> -- <dnf names>
pkg () {
    local apt_pkgs=() dnf_pkgs=() side=apt
    for word in "$@"; do
        if [ "${word}" = "--" ]; then side=dnf; continue; fi
        if [ "${side}" = apt ]; then apt_pkgs+=("${word}"); else dnf_pkgs+=("${word}"); fi
    done
    local list=() p
    if [ "${PM}" = apt ]; then list=("${apt_pkgs[@]}"); else list=("${dnf_pkgs[@]}"); fi
    [ ${#list[@]} -gt 0 ] || return 0
    # One unavailable/conflicting name makes apt/dnf install nothing at all. In that case
    # retry one by one so the rest still gets installed, and remember what failed.
    if ! sudo "${PM}" install -y "${list[@]}"; then
        echo "!! bulk install failed, retrying one package at a time"
        for p in "${list[@]}"; do
            sudo "${PM}" install -y "${p}" || FAILED_PACKAGES+=("${p}")
        done
    fi
}
FAILED_PACKAGES=()

# Commands the sway config needs; checked at the end of the script
verify_commands () {
    local missing=() c
    for c in sway swaybg swaylock swayidle swaymsg grim slurp swappy wl-copy wl-paste cliphist \
             wf-recorder brightnessctl gammastep wtype jq rofi dunst conky xsettingsd nm-applet \
             autotiling bumblebee-status flashfocus fcitx5 ibus-daemon; do
        command -v "${c}" >/dev/null 2>&1 || [ -x "$HOME/.local/bin/${c}" ] || [ -x "$HOME/go/bin/${c}" ] ||
            missing+=("${c}")
    done
    echo
    if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
        echo "!! Packages that failed to install: ${FAILED_PACKAGES[*]}"
    fi
    if [ ${#missing[@]} -gt 0 ]; then
        echo "!! Commands still missing: ${missing[*]}"
        echo "   (screenshots need grim + slurp; rerun Section 2 or install them by hand)"
    else
        echo "All commands used by the sway config are installed."
    fi
}

# ----------------------------------------------------------------------------
# Section 2 - Packages (each group: desc_<name> + install_<name>)
# ----------------------------------------------------------------------------

# Sway core (replaces: i3, i3bar, i3lock, xss-lock, i3-nagbar, feh wallpaper)
desc_sway_core_packages () {
    echo "Sway core packages including:"
    echo "-- Compositor/WM: sway (i3 replacement, includes swaybar, swaynag, swaymsg)"
    echo "-- Wallpaper: swaybg (feh --bg-* replacement, driven by 'output * bg')"
    echo "-- Lock/idle: swaylock, swayidle (i3lock + xss-lock + xset dpms replacement)"
    echo "-- XWayland: X11 compatibility server for X-only applications"
    echo "-- i3 IPC tools kept: i3-wm (provides i3-msg used by shared scripts), python i3ipc"
}
install_sway_core_packages () {
    pkg sway swaybg swaylock swayidle xwayland i3-wm jq python3-i3ipc \
        -- sway swaybg swaylock swayidle xorg-x11-server-Xwayland i3 jq python3-i3ipc
}

# Wayland session plumbing (portals, polkit, D-Bus env)
desc_session_packages () {
    echo "Session packages including:"
    echo "-- Portals: xdg-desktop-portal-wlr (screen sharing/screenshots), -gtk (file chooser)"
    echo "-- PipeWire: required by the portal for screen sharing (Zoom/Teams/browsers/OBS)"
    echo "-- polkit-gnome agent, gnome-keyring, libnotify (notify-send)"
    echo "-- Qt Wayland platform plugins (native Qt apps instead of XWayland)"
    echo "-- Started by sway_startup.config: xsettingsd (GTK settings for XWayland apps),"
    echo "   nm-applet (network tray), blueman-applet (bluetooth tray), xrdb (Xresources for XWayland)"
}
install_session_packages () {
    pkg xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
        pipewire wireplumber policykit-1-gnome gnome-keyring libnotify-bin \
        qtwayland5 qt6-wayland \
        xsettingsd network-manager-gnome blueman x11-xserver-utils libglib2.0-bin \
        -- xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
        pipewire wireplumber polkit-gnome gnome-keyring libnotify \
        qt5-qtwayland qt6-qtwayland \
        xsettingsd network-manager-applet blueman xrdb glib2
}

# Wayland replacements of X11 tools
desc_wayland_tool_packages () {
    echo "Wayland tool packages including (X11 tool -> Wayland tool):"
    echo "-- xclip/xsel -> wl-clipboard;  parcellite -> cliphist"
    echo "-- flameshot/gnome-screenshot -> grim + slurp + swappy"
    echo "-- peek -> wf-recorder;  screenkey -> showmethekey (built from source)"
    echo "-- xrandr/arandr/autorandr -> wdisplays, kanshi, wlr-randr;  mirroring -> wl-mirror"
    echo "-- xbacklight -> brightnessctl;  external monitor brightness -> ddcutil"
    echo "-- redshift -> gammastep"
    echo "-- xdotool -> wtype (keys) + ydotool (held modifiers) + native 'seat cursor'"
    echo "-- xcolor/gpick -> grim + slurp + imagemagick;  OCR/QR: tesseract, zbar"
    echo "-- terminal fallback: foot (Wayland-native)"
}
install_wayland_tool_packages () {
    pkg wl-clipboard grim slurp swappy wf-recorder wdisplays kanshi wlr-randr \
        brightnessctl ddcutil gammastep wtype ydotool imagemagick \
        tesseract-ocr tesseract-ocr-eng tesseract-ocr-chi-tra zbar-tools foot wl-mirror \
        libxkbcommon-tools bc psmisc translate-shell \
        -- wl-clipboard grim slurp swappy wf-recorder wdisplays kanshi wlr-randr \
        brightnessctl ddcutil gammastep wtype ydotool ImageMagick \
        tesseract tesseract-langpack-eng tesseract-langpack-chi_tra zbar foot wl-mirror \
        libxkbcommon-utils bc psmisc translate-shell
    # brightnessctl writes /sys/class/backlight -> user must be in 'video'
    sudo usermod -aG video "$USER"
    # ddcutil (external monitor brightness) needs i2c access
    sudo usermod -aG i2c "$USER" 2>/dev/null || true
    # ydotool needs /dev/uinput: run its daemon as a user service if provided
    if systemctl --user list-unit-files 2>/dev/null | grep -q '^ydotool.service'; then
        systemctl --user enable --now ydotool.service
    fi
    # cliphist (clipboard history for wl-clipboard)
    if ! pkg cliphist -- cliphist; then :; fi
    if ! command -v cliphist >/dev/null 2>&1; then
        pkg golang -- golang
        go install go.senan.xyz/cliphist@latest && echo "cliphist installed to ~/go/bin"
    fi
}

# Launcher / notifications / bar that work natively on Wayland
desc_desktop_packages () {
    echo "Desktop packages including:"
    echo "-- rofi with Wayland backend (rofi >= 2.0, or the rofi-wayland fork)"
    echo "-- dunst (>= 1.6 runs natively on Wayland)"
    echo "-- conky (>= 1.19 with out_to_wayland)"
    echo "-- bumblebee-status (swaybar status_command, unchanged from i3)"
    echo "-- autotiling, flashfocus (both support sway)"
    echo "-- omnisearch backends: fd, ripgrep, pdfgrep, sqlite3, poppler-utils"
}
install_desktop_packages () {
    pkg dunst conky-all fd-find ripgrep pdfgrep sqlite3 poppler-utils \
        -- dunst conky fd-find ripgrep pdfgrep sqlite poppler-utils
    # rofi: Fedora packages the Wayland fork; Ubuntu 24.04's rofi 1.7.5 is X11-only
    if [ "${PM}" = dnf ]; then
        sudo dnf install -y rofi-wayland
    else
        rofi_version=$(rofi -v 2>/dev/null | grep -oE '[0-9]+' | head -n1)
        if [ "${rofi_version:-0}" -lt 2 ]; then
            echo "Building rofi >= 2.0 (Wayland backend) from source ..."
            sudo apt install -y meson ninja-build bison flex pkg-config libglib2.0-dev \
                libcairo2-dev libpango1.0-dev libgdk-pixbuf-2.0-dev librsvg2-dev \
                libstartup-notification0-dev libxkbcommon-dev libxkbcommon-x11-dev \
                libxcb1-dev libxcb-xkb-dev libxcb-randr0-dev libxcb-xinerama0-dev \
                libxcb-util-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-cursor-dev \
                libxcb-imdkit-dev libwayland-dev wayland-protocols
            mkdir -p "${BUILD_DIR}" && cd "${BUILD_DIR}" || return
            [ -d rofi ] || git clone --recursive https://github.com/davatorium/rofi.git
            cd rofi && meson setup build -Dwayland=enabled -Dxcb=enabled --wipe 2>/dev/null \
                || meson setup build -Dwayland=enabled -Dxcb=enabled
            ninja -C build && sudo ninja -C build install
        fi
    fi
    # python3, not /usr/bin/python (absent on Ubuntu 24.04 without python-is-python3).
    # bumblebee-status is normally installed by the i3 script; installed here too because
    # swaybar shows "error from status command" without it.
    pkg python3-pip -- python3-pip
    python3 -m pip install autotiling flashfocus i3ipc bumblebee-status --user --break-system-packages
}

# Input method (ibus kept, fcitx5 recommended on sway)
desc_input_method_packages () {
    echo "Input method packages including:"
    echo "-- fcitx5 + fcitx5-chewing (best Wayland support: input-method-v2/text-input-v3,"
    echo "   StatusNotifier tray icon that swaybar can show)"
    echo "-- ibus/ibus-chewing are kept from the i3 install (XWayland apps and kitty only)"
    echo "-- switch inside sway: ~/.config/sway/script/sway_input_method.sh use fcitx5|ibus"
}
install_input_method_packages () {
    pkg fcitx5 fcitx5-chewing fcitx5-config-qt fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 fcitx5-frontend-qt5 \
        -- fcitx5 fcitx5-chewing fcitx5-configtool fcitx5-gtk fcitx5-qt
}

# Tools built from source (no distro package)
desc_source_build_packages () {
    echo "Source-built packages including:"
    echo "-- warpd (keyboard mouse emulator) rebuilt with PLATFORM=wayland"
    echo "-- showmethekey (screenkey replacement, reads libinput, needs root via pkexec)"
    echo "-- woomer (Wayland zoomer, replaces magnus/xzoom; needs cargo >= 1.85, a private"
    echo "   toolchain is installed in the build directory if the system cargo is older)"
}
install_source_build_packages () {
    mkdir -p "${BUILD_DIR}" && cd "${BUILD_DIR}" || return
    # warpd (Wayland backend)
    pkg libwayland-dev libxkbcommon-dev libcairo2-dev -- wayland-devel libxkbcommon-devel cairo-devel
    [ -d warpd ] || git clone https://github.com/rvaiya/warpd.git
    (cd warpd && make clean && PLATFORM=wayland make && sudo PLATFORM=wayland make install)
    # showmethekey (needs xkbregistry: libxkbregistry-dev on Ubuntu, part of
    # libxkbcommon-devel on Fedora)
    pkg meson ninja-build libgtk-4-dev libadwaita-1-dev libinput-dev libudev-dev libevdev-dev \
        libxkbcommon-dev libxkbregistry-dev libjson-glib-dev \
        -- meson ninja-build gtk4-devel libadwaita-devel libinput-devel systemd-devel libevdev-devel \
        libxkbcommon-devel json-glib-devel
    [ -d showmethekey ] || git clone https://github.com/AlynxZhou/showmethekey.git
    (
        cd showmethekey || exit 1
        git pull --ff-only || true
        if meson setup build --prefix=/usr/local --wipe 2>/dev/null || meson setup build --prefix=/usr/local; then
            ninja -C build && sudo ninja -C build install
        else
            echo "showmethekey: meson setup failed (see showmethekey/build/meson-logs/meson-log.txt)"
        fi
    )
    # woomer (Wayland zoomer)
    # -- Upstream's Cargo.toml points libwayshot at the branch "freeze-feat-andreas", which
    #    waycrate/wayshot deleted. The commit pinned in Cargo.lock still exists, so both
    #    files are switched from that branch to the same commit (rev) and built --locked.
    # -- The locked dependencies need cargo >= 1.85 (edition2024, lockfile v4). Ubuntu 24.04
    #    ships cargo 1.75 (test_v2: "feature edition2024 is required"), so an older cargo
    #    gets a private stable toolchain in ${BUILD_DIR}/rust. It does not touch ~/.cargo
    #    or the system cargo. woomer is installed to ~/.local/bin.
    # raylib-sys builds raylib with CMake and generates bindings with libclang
    pkg cmake clang libclang-dev pkg-config curl libwayland-dev wayland-protocols libxkbcommon-dev \
        libgbm-dev libegl-dev libgl-dev libx11-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev \
        -- cmake clang clang-devel pkgconf curl wayland-devel wayland-protocols-devel libxkbcommon-devel \
        mesa-libgbm-devel mesa-libEGL-devel mesa-libGL-devel libX11-devel libXrandr-devel libXinerama-devel libXcursor-devel libXi-devel
    local cargo_bin="cargo" cargo_minor
    cargo_minor=$(cargo --version 2>/dev/null | sed -nE 's/^cargo 1\.([0-9]+).*/\1/p')
    if [ "${cargo_minor:-0}" -lt 85 ]; then
        echo "cargo ${cargo_minor:+1.${cargo_minor} }is older than 1.85: installing a private Rust toolchain for woomer"
        export RUSTUP_HOME="${BUILD_DIR}/rust/rustup" CARGO_HOME="${BUILD_DIR}/rust/cargo"
        if [ ! -x "${CARGO_HOME}/bin/cargo" ]; then
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
                sh -s -- -y --no-modify-path --profile minimal --default-toolchain stable
        else
            "${CARGO_HOME}/bin/rustup" update stable
        fi
        cargo_bin="${CARGO_HOME}/bin/cargo"
    fi
    # raylib (woomer's renderer) is built with USE_EXTERNAL_GLFW and requires GLFW >= 3.4
    # (test_v4: "Could not find a package configuration file provided by glfw3 (requested
    # version 3.4)"). Fedora 40+ packages 3.4; Ubuntu 24.04 only 3.3.10 -> build 3.4 into
    # /usr/local (libdir lib/<triplet>, searched before the distro's /usr/lib/<triplet>).
    if ! pkg-config --atleast-version=3.4 glfw3 2>/dev/null; then
        if [ "${PM}" = dnf ]; then
            pkg -- glfw-devel
        fi
    fi
    if ! pkg-config --atleast-version=3.4 glfw3 2>/dev/null; then
        echo "GLFW < 3.4: building GLFW 3.4 (Wayland + X11) into /usr/local"
        pkg libwayland-bin libdecor-0-dev -- wayland-devel libdecor-devel
        [ -d glfw ] || git clone --branch 3.4 --depth 1 https://github.com/glfw/glfw.git
        triplet=$(gcc -dumpmachine)
        cmake -S glfw -B glfw/build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON \
            -DGLFW_BUILD_WAYLAND=ON -DGLFW_BUILD_X11=ON \
            -DGLFW_BUILD_EXAMPLES=OFF -DGLFW_BUILD_TESTS=OFF -DGLFW_BUILD_DOCS=OFF \
            -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR="lib/${triplet}" &&
            cmake --build glfw/build -j"$(nproc)" &&
            sudo cmake --install glfw/build && sudo ldconfig
        export PKG_CONFIG_PATH="/usr/local/lib/${triplet}/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
        export CMAKE_PREFIX_PATH="/usr/local${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
    fi
    [ -d woomer ] || git clone https://github.com/coffeeispower/woomer.git
    (
        cd woomer || exit 1
        git checkout -- Cargo.toml Cargo.lock 2>/dev/null
        git pull --ff-only || true
        if grep -q 'branch = "freeze-feat-andreas"' Cargo.toml; then
            rev=$(sed -nE 's/^source = "git\+https:\/\/github.com\/waycrate\/wayshot\?branch=freeze-feat-andreas#([0-9a-f]{40})"/\1/p' Cargo.lock | head -n1)
            rev=${rev:-0088b11b1880444f7a045c60559e156cf3f39eb8}
            sed -i "s#branch = \"freeze-feat-andreas\"#rev = \"${rev}\"#" Cargo.toml
            sed -i "s#wayshot?branch=freeze-feat-andreas\##wayshot?rev=${rev}\##" Cargo.lock
        fi
        # rust-lld only searches the -L paths it is given (test_v5: "unable to find library
        # -lglfw"): add the GLFW 3.4 libdir, and an rpath so woomer loads that 3.4 at runtime
        triplet=$(gcc -dumpmachine)
        RUSTFLAGS="-L /usr/local/lib/${triplet} -C link-arg=-Wl,-rpath,/usr/local/lib/${triplet}" \
        "${cargo_bin}" install --locked --path . --root "$HOME/.local" --force ||
            echo "woomer: build failed; the magnifier binding falls back to a notification"
    )
    unset RUSTUP_HOME CARGO_HOME CMAKE_PREFIX_PATH
}

# Image previews in the terminal (ranger preview_images_method ueberzug)
desc_ueberzugpp_packages () {
    echo "ueberzugpp (drop-in ueberzug replacement with a native Wayland output)"
    echo "-- X11 ueberzug cannot draw over terminals on sway; ~/.config/sway/bin/ueberzug"
    echo "   redirects ranger's 'ueberzug layer' to 'ueberzugpp layer --output wayland'"
    echo "-- Source: openSUSE Build Service repository home:justkidding (ueberzugpp's author)"
}
install_ueberzugpp_packages () {
    if [ "${PM}" = dnf ]; then
        if ! sudo dnf install -y ueberzugpp; then
            fedora=$(rpm -E %fedora)
            repo="https://download.opensuse.org/repositories/home:justkidding/Fedora_${fedora}/home:justkidding.repo"
            sudo dnf config-manager addrepo --from-repofile="${repo}" 2>/dev/null ||
                sudo dnf config-manager --add-repo "${repo}"
            sudo dnf install -y ueberzugpp
        fi
    else
        . /etc/os-release
        obs="https://download.opensuse.org/repositories/home:/justkidding/xUbuntu_${VERSION_ID}"
        echo "deb ${obs}/ /" | sudo tee /etc/apt/sources.list.d/home:justkidding.list > /dev/null
        curl -fsSL "${obs}/Release.key" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_justkidding.gpg > /dev/null
        sudo apt update && sudo apt install -y ueberzugpp
    fi
}

# Optional: SwayFX (blur, shadows, rounded corners = the picom effects)
desc_swayfx_packages () {
    echo "Optional SwayFX (drop-in sway fork with blur/shadows/rounded corners/dim_inactive)"
    echo "-- Fedora: COPR swayfx/swayfx;  Ubuntu: build from source (not packaged)"
}
install_swayfx_packages () {
    if [ "${PM}" = dnf ]; then
        sudo dnf copr enable -y swayfx/swayfx && sudo dnf install -y swayfx
    else
        echo "SwayFX is not packaged for ${PRETTY_NAME}."
        echo "See https://github.com/WillPower3309/swayfx#compiling-from-source"
    fi
}

PACKAGE_LIST=( \
    sway_core_packages \
    session_packages \
    wayland_tool_packages \
    desktop_packages \
    input_method_packages \
    source_build_packages \
    ueberzugpp_packages \
    swayfx_packages \
)

echo
echo '# ========== Section 2 - Sway packages ========== #'
echo "Do you want to install the packages needed for the sway environment ?"
select option_section2 in 'no' 'yes (one-by-one)' 'yes (all)'
do
    case ${option_section2} in
        'no')
            echo "Package installation is ignored ..."
            break ;;
        'yes (one-by-one)')
            [ "${PM}" = apt ] && sudo apt update
            for package in "${PACKAGE_LIST[@]}"; do
                echo; echo "Do you want to install ${package} ?"
                "desc_${package}"; echo
                select option in 'no' 'yes'
                do
                    case ${option} in
                        'no')  echo "${package} is ignored ..."; break ;;
                        'yes') "install_${package}"; echo "${package} installation is done ..."; break ;;
                    esac
                done
            done
            break ;;
        'yes (all)')
            [ "${PM}" = apt ] && sudo apt update
            for package in "${PACKAGE_LIST[@]}"; do
                [ "${package}" = swayfx_packages ] && continue   # optional, ask explicitly
                echo; echo "${package}"; "desc_${package}"; echo
                "install_${package}"
            done
            echo "Package installation is done (SwayFX skipped; use one-by-one to install it) ..."
            break ;;
    esac
done

# ----------------------------------------------------------------------------
# Section 3 - Configuration links and session entry
# ----------------------------------------------------------------------------
echo
echo '# ========== Section 3 - Configuration ========== #'
echo "Link sway config, pywal template, session launcher and login-manager entry ?"
select option_section3 in 'no' 'yes'
do
    case ${option_section3} in
        'no') echo "Configuration is ignored ..."; break ;;
        'yes')
            # ~/.config/sway -> repo (back up an existing non-link directory)
            if [ -e "${USER_CONFIG_DIR}/sway" ] && [ ! -L "${USER_CONFIG_DIR}/sway" ]; then
                mv "${USER_CONFIG_DIR}/sway" "${USER_CONFIG_DIR}/sway_backup_$(date +%Y%m%d_%H%M%S)"
            fi
            ln -sfn "${NEW_CONFIG_DIR}/sway" "${USER_CONFIG_DIR}/sway"
            # pywal user template that replaces Xresources/set_from_resource for sway
            mkdir -p "${USER_CONFIG_DIR}/wal/templates"
            ln -sf "${NEW_CONFIG_DIR}/sway/share/wal_templates/colors-sway-i3" \
                "${USER_CONFIG_DIR}/wal/templates/colors-sway-i3"
            # Generate the palette once so the first sway start already has wal colors
            command -v wal >/dev/null && wal -n -s -t -q -i "${NEW_CONFIG_DIR}/i3/share/default_wallpaper"
            # xdg-desktop-portal routing for XDG_CURRENT_DESKTOP=sway: screen sharing and
            # screenshots through -wlr, file chooser etc. through -gtk
            mkdir -p "${USER_CONFIG_DIR}/xdg-desktop-portal"
            ln -sf "${NEW_CONFIG_DIR}/sway/share/sway-portals.conf" \
                "${USER_CONFIG_DIR}/xdg-desktop-portal/sway-portals.conf"
            # Input method + PATH variables for every session start (GDM imports
            # ~/.config/environment.d), so they do not depend on the sway-session launcher
            "${NEW_CONFIG_DIR}/sway/script/sway_input_method.sh" write_env
            # flameshot: capture with grim instead of the portal when flameshot supports it
            # (ignored by builds without the grim adapter)
            FLAMESHOT_INI="${USER_CONFIG_DIR}/flameshot/flameshot.ini"
            mkdir -p "$(dirname "${FLAMESHOT_INI}")"
            [ -f "${FLAMESHOT_INI}" ] || printf '[General]\n' > "${FLAMESHOT_INI}"
            grep -q '^\[General\]' "${FLAMESHOT_INI}" || printf '[General]\n' >> "${FLAMESHOT_INI}"
            for kv in useGrimAdapter=true disabledGrimWarning=true; do
                grep -q "^${kv%%=*}=" "${FLAMESHOT_INI}" ||
                    sed -i "/^\[General\]/a ${kv}" "${FLAMESHOT_INI}"
            done
            # Session launcher (sources ~/.profile, exports Wayland toolkit variables)
            sudo install -m 755 "${NEW_CONFIG_DIR}/sway/script/sway_session.sh" /usr/local/bin/sway-session
            sudo install -m 644 "${NEW_CONFIG_DIR}/sway/share/sway-session.desktop" \
                /usr/share/wayland-sessions/sway-session.desktop
            # The stock "Sway" entry starts plain `sway`, which skips ~/.profile and the input
            # method variables (test_v3/v4: chosen on the login screen, so ibus/fcitx5 got no
            # variables; GDM did not import ~/.config/environment.d either). Point it at
            # sway-session too. apt: dpkg-divert keeps the package's file as sway.desktop.distrib
            # and survives sway upgrades. dnf: overwritten (restored by a sway package update).
            stock=/usr/share/wayland-sessions/sway.desktop
            if [ "${PM}" = apt ] && ! dpkg-divert --list "${stock}" | grep -q .; then
                sudo dpkg-divert --local --rename --add "${stock}"
            fi
            sed 's/^Name=.*/Name=Sway/' "${NEW_CONFIG_DIR}/sway/share/sway-session.desktop" |
                sudo tee "${stock}" > /dev/null
            echo "Both 'Sway' and 'Sway (user session)' now start /usr/local/bin/sway-session."
            echo "Select 'Sway (user session)' on the login screen, or run 'sway-session' from a TTY."
            break ;;
    esac
done

# ----------------------------------------------------------------------------
# Section 4 - Post-installation
# ----------------------------------------------------------------------------
echo
verify_commands
echo
echo "Post-installation TODO things"
echo "(1) log out and back in (group changes: video, i2c, input)"
echo "(2) check output names: swaymsg -t get_outputs  -> update \$monitor1..5 in ~/.config/sway/config"
echo "(3) validate the config: sway -C -c ~/.config/sway/config"
echo "(4) optional kanshi profiles: ~/.config/kanshi/config (see doc/03_X11_TO_WAYLAND_CHANGES.md)"
echo "(5) input method: ~/.config/sway/script/sway_input_method.sh use fcitx5   (or ibus), then re-login"
echo "(6) read config/sway/doc/00_MIGRATION_OVERVIEW.md"
