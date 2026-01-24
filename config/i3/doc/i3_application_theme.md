# Sync Theme Across Applications in Linux Desktop Environment

- References
  - https://www.youtube.com/watch?v=8HkwY9ORHyQ&t=2s

## GTK

- Set environment variables in profile
  ```sh
  echo ADW_DISABLE_PORTAL=1 >> /etc/environment
  echo ADW_DEBUG_COLOR_SCHEME=prefer-dark >> /etc/environment
  ```
- Prefer dark theme
  ```sh
  # Set GNOME libadwaita to prefer dark
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
  ```

## QT

- Install packages
  ```sh
  sudo apt install qt5ct qt6ct qt5-style-kvantum-themes qt5-style-kvantum
  ```
- Set environment variables in profile
  ```sh
  echo QT_QPA_PLATFORMTHEME=qt5ct >> /etc/environment
  echo QT_STYLE_OVERRIDE=kvantum >> /etc/environment
  ```
- Setup QT theme w/ Kvantum
  ```sh
  if command -v kvantummanager > /dev/null; then
      kvantummanager --set KvGnomeDark
  else
      # Fallback: Manual config edit if kvantummanager CLI isn't responsive
      sed -i 's/theme=.*/theme=KvGnomeDark/' ~/.config/Kvantum/kvantum.kvconfig
  fi
  ```

## XSettings Daemon

- Install packages
  ```sh
  sudo apt install xsettingsd

  ```
- In `~/.xsettingsd`, add
  ```
  Net/ThemeName "Adwaita-dark"
  Gtk/TargetFormat "dark"
  ```

## Flatpak

## Snap
