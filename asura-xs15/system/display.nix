# Display and Input Configuration
{ ... }:

{
  services.xserver = {
    enable = false;
    xkb = {
      layout = "us";
      options = "caps:escape";
    };
    videoDrivers = [ "nvidia" ];
  };

  services.libinput.enable = true;
}
