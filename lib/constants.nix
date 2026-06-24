# Shared constants: host names, primary user, target system, and allowed shell choices.
{
  username = "asura";
  system = "x86_64-linux";
  hosts = {
    laptop = "asura-xs15";
    pc = "asura-pc";
  };
  allowedShells = [
    "waybar"
    "noctalia"
    "vibeshell"
  ];
}
