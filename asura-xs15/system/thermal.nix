# Thermal management. NBFC-specific fan control lives in the fan-control-tools module.
{ pkgs, lib, ... }:

{
  services.thermald.enable = true;

  # Noctalia's power UI uses tuned. Keep TLP disabled to avoid split ownership.
  services.tlp.enable = lib.mkForce false;
  services.auto-cpufreq.enable = false;
  services.power-profiles-daemon.enable = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    lm_sensors
    acpi
    powertop
  ];

  boot.kernelModules = [
    "coretemp"
  ];

  boot.kernelParams = [
    "acpi_enforce_resources=lax"
  ];
}
