# Laptop-specific module: XS15 display driver and libinput baseline.
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
