# fastfetch — compact Kitty image logo + system info
{ ... }:

let
  logoImage = ../../../assets/sans.png;
  cfg = {
    "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
    logo = {
      type = "kitty-direct";
      source = "${logoImage}";
      width = 18;
      height = 9;
      position = "left";
      padding = {
        top = 3;
        left = 1;
        right = 2;
      };
    };
    display = {
      separator = "";
    };
    modules = [
      {
        type = "custom";
        format = "┌─────────────┐";
      }
      {
        type = "title";
        key = "│ {#90} user      │ ";
        format = "{1}";
      }
      {
        type = "uptime";
        key = "│ {#90} uptime    │ ";
      }
      {
        type = "display";
        key = "│ {#90} display   │ ";
      }
      {
        type = "os";
        key = "│ {#90} distro    │ ";
      }
      {
        type = "kernel";
        key = "│ {#90} kernel    │ ";
      }
      {
        type = "wm";
        key = "│ {#90} wm        │ ";
      }
      {
        type = "terminal";
        key = "│ {#90} term      │ ";
      }
      {
        type = "shell";
        key = "│ {#90} shell     │ ";
      }
      {
        type = "packages";
        key = "│ {#90} apps      │ ";
      }
      {
        type = "disk";
        key = "│ {#90} disk      │ ";
      }
      {
        type = "memory";
        key = "│ {#90} memory    │ ";
      }
      {
        type = "font";
        key = "│ {#90} font      │ ";
      }
      {
        type = "command";
        key = "│ {#90} OS Age    │ ";
        shell = "/bin/sh";
        text = "birth=$(stat -c %Y /); current=$(date +%s); age=$(( (current - birth) / 86400 )); echo \"$age days\"";
      }
      {
        type = "custom";
        format = "├─────────────┤";
      }
      {
        type = "colors";
        key = "│ {#90} colors    │ ";
        symbol = "circle";
      }
      {
        type = "custom";
        format = "└─────────────┘";
      }
    ];
  };
in
{
  xdg.configFile."fastfetch/config.jsonc" = {
    force = true;
    text = builtins.toJSON cfg;
  };
}
