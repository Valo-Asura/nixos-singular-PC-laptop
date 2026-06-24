# PC-specific module: NVIDIA X/Wayland driver selection.
{ ... }:

{
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      options = "caps:escape";
    };
    videoDrivers = [ "nvidia" ];
  };

  services.libinput.enable = true;
}
