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
        key = "{#90}┌─────────────┐";
        format = "";
      }
      {
        type = "title";
        key = "{#90}│ {#37} user      {#90}│ ";
        format = "{1}";
      }
      {
        type = "uptime";
        key = "{#90}│ {#37} uptime    {#90}│ ";
      }
      {
        type = "display";
        key = "{#90}│ {#37} display   {#90}│ ";
      }
      {
        type = "os";
        key = "{#90}│ {#37} distro    {#90}│ ";
      }
      {
        type = "kernel";
        key = "{#90}│ {#37} kernel    {#90}│ ";
      }
      {
        type = "wm";
        key = "{#90}│ {#37} wm        {#90}│ ";
      }
      {
        type = "terminal";
        key = "{#90}│ {#37} term      {#90}│ ";
      }
      {
        type = "shell";
        key = "{#90}│ {#37} shell     {#90}│ ";
      }
      {
        type = "packages";
        key = "{#90}│ {#37} apps      {#90}│ ";
      }
      {
        type = "disk";
        key = "{#90}│ {#37} disk      {#90}│ ";
      }
      {
        type = "memory";
        key = "{#90}│ {#37} memory    {#90}│ ";
      }
      {
        type = "font";
        key = "{#90}│ {#37} font      {#90}│ ";
      }
      {
        type = "command";
        key = "{#90}│ {#37} OS Age    {#90}│ ";
        shell = "/bin/sh";
        text = "birth=$(stat -c %Y /); current=$(date +%s); age=$(( (current - birth) / 86400 )); echo \"$age days\"";
      }
      {
        type = "custom";
        key = "{#90}├─────────────┤";
        format = "";
      }
      {
        type = "colors";
        key = "{#90}│ {#37} colors    {#90}│ ";
        symbol = "circle";
      }
      {
        type = "custom";
        key = "{#90}└─────────────┘";
        format = "";
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
