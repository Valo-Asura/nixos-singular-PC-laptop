# Shared Home Manager module: Hyprlock lockscreen defaults for all Asura hosts.
{ pkgs, ... }:
{
  programs.hyprlock = {
    enable = true;
    package = pkgs.hyprlock;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = false;
        no_fade_in = false;
        no_fade_out = false;
      };

      background = [
        {
          monitor = "";
          path = "/etc/nixos/assets/she.jpg";
          blur_passes = 2;
          blur_size = 4;
          noise = 0.0117;
          contrast = 1.05;
          brightness = 0.55;
          vibrancy = 0.2;
          vibrancy_darkness = 0.35;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "340, 58";
          position = "0, -230";
          dots_center = true;
          fade_on_empty = false;
          outline_thickness = 1;
          rounding = 14;
          inner_color = "rgba(1a1010dd)";
          outer_color = "rgba(ffaaaacc)";
          font_color = "rgba(ffe7e7ff)";
          placeholder_text = "<i>unlock Asura</i>";
          fail_text = "<i>try again</i>";
          check_color = "rgba(f9c2c2ff)";
          fail_color = "rgba(ff6b6bff)";
        }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME12";
          color = "rgba(ffe7e7ff)";
          font_size = 54;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, -120";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "Asura";
          color = "rgba(ffaaaaff)";
          font_size = 15;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, -170";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
