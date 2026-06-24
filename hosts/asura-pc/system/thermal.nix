# PC-specific module: AMD desktop thermal monitoring and tuned ownership.
{ lib, pkgs, ... }:

{
  services.thermald.enable = true;

  services.tlp.enable = lib.mkForce false;
  services.auto-cpufreq.enable = false;
  services.power-profiles-daemon.enable = lib.mkForce false;
  services.tuned = {
    enable = true;
    settings = {
      dynamic_tuning = true;
      sleep_interval = 1;
      update_interval = 5;
    };
    profiles = {
      asura-pc-balanced = {
        main = {
          summary = "Asura PC balanced desktop profile";
          include = "balanced";
        };
        cpu = {
          governor = "schedutil|powersave";
          energy_perf_bias = "normal";
          energy_performance_preference = "balance_performance";
          boost = 1;
        };
      };

      asura-pc-performance = {
        main = {
          summary = "Asura PC performance desktop profile";
          include = "balanced";
        };
        cpu = {
          governor = "schedutil|performance";
          energy_perf_bias = "performance";
          energy_performance_preference = "performance";
          boost = 1;
        };
      };
    };
    ppdSettings = {
      main.default = "balanced";
      profiles = {
        balanced = "asura-pc-balanced";
        performance = "asura-pc-performance";
        power-saver = "balanced";
      };
    };
    recommend.asura-pc-balanced = { };
  };

  environment.systemPackages = with pkgs; [
    lm_sensors
    acpi
    powertop
  ];

  boot.kernelModules = [
    "k10temp"
  ];

  boot.kernelParams = [
    "acpi_enforce_resources=lax"
  ];
}
