# Shared Home Manager module: user application settings.
{ pkgs, lib, ... }:

{
  imports = [
    ../application.nix
  ];

  services.easyeffects = {
    enable = true;
  };

  # Ensure EasyEffects service starts only after PipeWire and WirePlumber are active,
  # preventing crashes on startup and ensuring audio devices (mic/speaker) are correctly sensed.
  systemd.user.services.easyeffects.Unit = {
    After = lib.mkForce [ "graphical-session.target" "pipewire.service" "wireplumber.service" ];
    Requires = [ "pipewire.service" ];
  };

  # Override standard ExecStart to use --service-mode and set resource constraints
  systemd.user.services.easyeffects.Service = {
    ExecStart = lib.mkForce "${pkgs.easyeffects}/bin/easyeffects --service-mode --hide-window";
  };

  # Configure GSettings/dconf settings for EasyEffects to run properly in the background
  # and process all audio streams (microphone and speaker) automatically.
  dconf.settings = {
    "com/github/wwmm/easyeffects" = {
      process-all-inputs = true;
      process-all-outputs = true;
      shutdown-on-window-close = false;
    };
  };
}
