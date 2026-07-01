# Theming configuration
# Stylix owns the base theme. We add a few desktop-specific keys on top.
{ config, lib, pkgs, ... }:

let
  qtMaterialDarkColors = ''
    [ColorScheme]
    active_colors=#ffe6e1e5, #ff1d1b20, #ff49454f, #ff36343b, #ff141218, #ff2b2930, #ffe6e1e5, #ffffffff, #ffe6e1e5, #ff141218, #ff1d1b20, #ff000000, #ffd0bcff, #ff381e72, #ffd0bcff, #ffefb8c8, #ff211f26, #ffe6e1e5, #ff141218, #ffcac4d0, #ff6750a4
    disabled_colors=#ff938f99, #ff1d1b20, #ff36343b, #ff2b2930, #ff141218, #ff211f26, #ff938f99, #ffffffff, #ff938f99, #ff141218, #ff1d1b20, #ff000000, #ff49454f, #ff1d1b20, #ff938f99, #ff938f99, #ff211f26, #ff938f99, #ff141218, #ff938f99, #ff49454f
    inactive_colors=#ffe6e1e5, #ff1d1b20, #ff49454f, #ff36343b, #ff141218, #ff2b2930, #ffe6e1e5, #ffffffff, #ffe6e1e5, #ff141218, #ff1d1b20, #ff000000, #ffcac4d0, #ff211f26, #ffd0bcff, #ffefb8c8, #ff211f26, #ffe6e1e5, #ff141218, #ffcac4d0, #ff6750a4
  '';
in
{
  stylix.targets.gtk.enable = false;

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Amber";
      package = pkgs.bibata-cursors;
      size = 24;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.theme = config.gtk.theme;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  home.sessionVariables = {
    GTK_THEME = "adw-gtk3-dark";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_CLASS = "user";
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };

  dconf.enable = true;

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "Papirus-Dark";
      cursor-theme = "Bibata-Modern-Amber";
      cursor-size = 24;
    };

    "org/gtk/settings/file-chooser" = {
      location-mode = "filename-entry";
      show-hidden = true;
      show-size-column = true;
      show-type-column = true;
      sort-directories-first = true;
      startup-mode = "cwd";
      window-size = lib.hm.gvariant.mkTuple [
        1100
        720
      ];
    };

    "org/gnome/nautilus/preferences" = {
      show-hidden-files = true;
    };

    "org.cinnamon.desktop.interface" = {
      gtk-theme = "Stylix";
      icon-theme = "Papirus-Dark";
      cursor-theme = "Bibata-Modern-Amber";
      cursor-size = 24;
    };
  };

  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;
  xdg.configFile."qt5ct/colors/noctalia.colors".text = qtMaterialDarkColors;
  xdg.configFile."qt6ct/colors/noctalia.colors".text = qtMaterialDarkColors;

  xdg.configFile."qt5ct/qt5ct.conf" = {
    force = true;
    text = ''
      [Appearance]
      color_scheme_path=${config.home.homeDirectory}/.config/qt5ct/colors/noctalia.colors
      custom_palette=true
      icon_theme=Papirus-Dark
      standard_dialogs=default
      style=Fusion

      [Fonts]
      fixed="JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
      general="JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"

      [Interface]
      activate_item_on_single_click=0
      buttonbox_layout=0
      cursor_flash_time=1000
      dialog_buttons_have_icons=1
      double_click_interval=400
      gui_effects=@Invalid()
      keyboard_scheme=2
      menus_have_icons=true
      show_shortcuts_in_context_menus=true
      stylesheets=@Invalid()
      toolbutton_style=4
      underline_shortcut=1
      wheel_scroll_lines=3

      [SettingsWindow]
      geometry=@ByteArray()
    '';
  };

  xdg.configFile."qt6ct/qt6ct.conf" = {
    force = true;
    text = ''
      [Appearance]
      color_scheme_path=${config.home.homeDirectory}/.config/qt6ct/colors/noctalia.colors
      custom_palette=true
      icon_theme=Papirus-Dark
      standard_dialogs=default
      style=Fusion

      [Fonts]
      fixed="JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
      general="JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"

      [Interface]
      activate_item_on_single_click=0
      buttonbox_layout=0
      cursor_flash_time=1000
      dialog_buttons_have_icons=1
      double_click_interval=400
      gui_effects=@Invalid()
      keyboard_scheme=2
      menus_have_icons=true
      show_shortcuts_in_context_menus=true
      stylesheets=@Invalid()
      toolbutton_style=4
      underline_shortcut=1
      wheel_scroll_lines=3

      [SettingsWindow]
      geometry=@ByteArray()
    '';
  };
}
