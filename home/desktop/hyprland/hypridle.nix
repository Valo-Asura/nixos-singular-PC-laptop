# Shared Home Manager module: Hypridle idle actions for the common Hyprland desktop.
# Hypridle listens for user activity and runs commands when the user is idle.
{ ... }:
{
  services.hypridle = {
    enable = true;
    settings = {

      general = {
        ignore_dbus_inhibit = false;
        ignore_systemd_inhibit = false;
        lock_cmd = "/run/current-system/sw/bin/asura-session-lock";
        before_sleep_cmd = "/run/current-system/sw/bin/asura-session-lock";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 600;
          on-timeout = "/run/current-system/sw/bin/asura-session-lock";
        }

        {
          timeout = 660;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
