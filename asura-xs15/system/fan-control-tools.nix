# NBFC fan control for the Colorful XS 22 / X15 XS laptop.
{
  lib,
  pkgs,
  ...
}:

let
  modelConfigPath = "/etc/nbfc/Colorful X15 AT 22.json";

  nbfcLinux = pkgs.nbfc-linux.overrideAttrs (_old: {
    version = "0.5.2";
    src = pkgs.fetchFromGitHub {
      owner = "nbfc-linux";
      repo = "nbfc-linux";
      tag = "0.5.2";
      hash = "sha256-468/dFRjEgyJ0AW98wKq04WKZ4sZyzswBASSF6hyjVY=";
    };
    nativeBuildInputs = with pkgs; [
      autoreconfHook
      pkg-config
    ];
    buildInputs = with pkgs; [
      curl
      libxml2
      lua5_4
      openssl
    ];
    configureFlags = [
      "--prefix=${placeholder "out"}"
      "--sysconfdir=${placeholder "out"}/etc"
      "--bindir=${placeholder "out"}/bin"
      "--with-init-system=systemd"
    ];
  });

  pythonWithGtk = pkgs.python3.withPackages (ps: [
    ps.pygobject3
  ]);

  nbfcGtk = pkgs.stdenvNoCC.mkDerivation {
    pname = "nbfc-gtk";
    version = "0.4.1";

    src = pkgs.fetchFromGitHub {
      owner = "nbfc-linux";
      repo = "nbfc-gtk";
      tag = "0.4.1";
      hash = "sha256-2ko957V5SqhnxdZxtbkjMsHbvThag55divZlftrWgRI=";
    };

    nativeBuildInputs = with pkgs; [
      makeWrapper
      pythonWithGtk
      wrapGAppsHook4
    ];

    buildInputs = with pkgs; [
      gtk4
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild
      make nbfc-gtk.py
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 nbfc-gtk.py "$out/bin/nbfc-gtk"
      patchShebangs "$out/bin/nbfc-gtk"
      runHook postInstall
    '';

    preFixup = ''
      gappsWrapperArgs+=(
        --prefix PATH : ${
          lib.makeBinPath [
            nbfcLinux
            pkgs.systemd
            pkgs.xdg-utils
          ]
        }
      )
    '';

    meta = {
      description = "GTK fan-control GUI for NBFC-Linux";
      homepage = "https://github.com/nbfc-linux/nbfc-gtk";
      license = lib.licenses.gpl3Only;
      mainProgram = "nbfc-gtk";
      platforms = lib.platforms.linux;
    };
  };

  nbfcGtkDesktop = pkgs.makeDesktopItem {
    name = "nbfc-gtk-fan-control";
    desktopName = "NBFC Fan Control";
    genericName = "Laptop fan control";
    comment = "Control the Colorful XS laptop fans through NBFC";
    exec = "nbfc-gtk --fans";
    icon = "utilities-system-monitor";
    categories = [
      "System"
      "Settings"
    ];
  };

  nbfcConfig = {
    NotebookModel = "Colorful X15 AT 22";
    Author = "sek1ro; NixOS declarative two-fan 8-bit PWM profile";
    EcPollInterval = 100;
    ReadWriteWords = false;
    CriticalTemperature = 77;
    CriticalTemperatureOffset = 7;
    FanConfigurations = [
      {
        ReadRegister = 207;
        WriteRegister = 231;
        MinSpeedValue = 20;
        MaxSpeedValue = 255;
        IndependentReadMinMaxValues = false;
        MinSpeedValueRead = 0;
        MaxSpeedValueRead = 0;
        ResetRequired = false;
        FanSpeedResetValue = 50;
        FanDisplayName = "CPU Fan";
        TemperatureThresholds = [
          {
            UpThreshold = 20;
            DownThreshold = 0;
            FanSpeed = 0.0;
          }
          {
            UpThreshold = 50;
            DownThreshold = 20;
            FanSpeed = 23.0769234;
          }
          {
            UpThreshold = 60;
            DownThreshold = 50;
            FanSpeed = 50.0;
          }
          {
            UpThreshold = 65;
            DownThreshold = 55;
            FanSpeed = 70.0;
          }
          {
            UpThreshold = 70;
            DownThreshold = 60;
            FanSpeed = 90.0;
          }
          {
            UpThreshold = 76;
            DownThreshold = 60;
            FanSpeed = 100.0;
          }
        ];
        FanSpeedPercentageOverrides = [
          {
            FanSpeedPercentage = 100.0;
            FanSpeedValue = 255;
            TargetOperation = "ReadWrite";
          }
        ];
      }
      {
        ReadRegister = 208;
        WriteRegister = 232;
        MinSpeedValue = 20;
        MaxSpeedValue = 255;
        IndependentReadMinMaxValues = false;
        MinSpeedValueRead = 0;
        MaxSpeedValueRead = 0;
        ResetRequired = false;
        FanSpeedResetValue = 50;
        FanDisplayName = "GPU Fan";
        TemperatureThresholds = [
          {
            UpThreshold = 20;
            DownThreshold = 0;
            FanSpeed = 0.0;
          }
          {
            UpThreshold = 50;
            DownThreshold = 20;
            FanSpeed = 23.0769234;
          }
          {
            UpThreshold = 60;
            DownThreshold = 50;
            FanSpeed = 50.0;
          }
          {
            UpThreshold = 65;
            DownThreshold = 55;
            FanSpeed = 70.0;
          }
          {
            UpThreshold = 70;
            DownThreshold = 60;
            FanSpeed = 90.0;
          }
          {
            UpThreshold = 76;
            DownThreshold = 60;
            FanSpeed = 100.0;
          }
        ];
        FanSpeedPercentageOverrides = [
          {
            FanSpeedPercentage = 100.0;
            FanSpeedValue = 255;
            TargetOperation = "ReadWrite";
          }
        ];
      }
    ];
    RegisterWriteConfigurations = [
      {
        WriteMode = "Set";
        WriteOccasion = "OnInitialization";
        Register = 44;
        Value = 8;
        ResetRequired = true;
        ResetValue = 5;
        ResetWriteMode = "Set";
        Description = "Enable manual EC fan override";
      }
    ];
  };

  serviceConfig = {
    SelectedConfigId = modelConfigPath;
    EmbeddedControllerType = "ec_sys";
  };

  nbfcVerify = pkgs.writeShellScriptBin "nbfc-colorful-verify" ''
    set -euo pipefail

    config_file=/etc/nbfc/nbfc.json
    model_file=${lib.escapeShellArg modelConfigPath}

    echo "NBFC Colorful XS verification"
    echo "service config: $config_file"
    echo "model config:   $model_file"
    echo

    selected="$(${pkgs.jq}/bin/jq -r '.SelectedConfigId' "$config_file")"
    ec_type="$(${pkgs.jq}/bin/jq -r '.EmbeddedControllerType // "auto"' "$config_file")"
    fan_count="$(${pkgs.jq}/bin/jq '.FanConfigurations | length' "$model_file")"
    max_values="$(${pkgs.jq}/bin/jq -r '[.FanConfigurations[].MaxSpeedValue] | join(",")' "$model_file")"
    writes="$(${pkgs.jq}/bin/jq -r '[.FanConfigurations[].WriteRegister] | join(",")' "$model_file")"
    reads="$(${pkgs.jq}/bin/jq -r '[.FanConfigurations[].ReadRegister] | join(",")' "$model_file")"

    test "$selected" = "$model_file"
    test "$ec_type" = "ec_sys"
    test "$fan_count" = "2"
    test "$max_values" = "255,255"
    test "$writes" = "231,232"
    test "$reads" = "207,208"

    echo "OK: selected config is absolute"
    echo "OK: EC backend is ec_sys"
    echo "OK: fan count is 2"
    echo "OK: MaxSpeedValue is 255 for both fans"
    echo "OK: CPU/GPU write registers are 231/232"
    echo "OK: CPU/GPU read registers are 207/208"
    echo "NOTE: GPU current-speed readback can report a negative/low value on this EC."
    echo "      Use Target Fan Speed plus audible airflow for manual GPU fan tests."
    echo

    if ${pkgs.systemd}/bin/systemctl is-active --quiet nbfc; then
      echo "Live NBFC status:"
      ${nbfcLinux}/bin/nbfc status
    else
      echo "NBFC service is not active yet. Rebuild/switch, then run: systemctl status nbfc"
    fi
  '';

  thermalStatus = pkgs.writeShellScriptBin "thermal-status" ''
    set -euo pipefail

    echo "System thermal status"
    echo "====================="

    if command -v sensors >/dev/null 2>&1; then
      echo
      echo "CPU temperature:"
      sensors | grep -E "(Core|Package|Tctl)" | head -8 || true
    fi

    echo
    echo "Thermal services:"
    ${pkgs.systemd}/bin/systemctl is-active thermald >/dev/null 2>&1 && echo "thermald: active" || echo "thermald: inactive"
    ${pkgs.systemd}/bin/systemctl is-active tuned >/dev/null 2>&1 && echo "tuned: active" || echo "tuned: inactive"
    ${pkgs.systemd}/bin/systemctl is-active tlp >/dev/null 2>&1 && echo "tlp: active (unexpected)" || echo "tlp: inactive"

    echo
    echo "NBFC:"
    if ${pkgs.systemd}/bin/systemctl is-active --quiet nbfc; then
      ${nbfcLinux}/bin/nbfc status
    else
      echo "nbfc: inactive"
    fi
  '';

  thermalMonitor = pkgs.writeShellScriptBin "thermal-monitor" ''
    set -euo pipefail

    while true; do
      clear
      date
      thermal-status
      sleep 2
    done
  '';
in
{
  environment.systemPackages = [
    nbfcLinux
    nbfcGtk
    nbfcGtkDesktop
    nbfcVerify
    thermalMonitor
    thermalStatus
  ];

  environment.etc = {
    "nbfc/nbfc.json".text = builtins.toJSON serviceConfig;
    "nbfc/Colorful X15 AT 22.json".text = builtins.toJSON nbfcConfig;
  };

  boot.kernelModules = [ "ec_sys" ];
  boot.extraModprobeConfig = ''
    options ec_sys write_support=1
  '';

  systemd.services.nbfc = {
    description = "NoteBook FanControl service";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [
      nbfcLinux
      pkgs.coreutils
      pkgs.jq
      pkgs.kmod
      pkgs.systemd
      pkgs.util-linux
    ];
    preStart = ''
      modprobe ec_sys write_support=1 || true

      if ! mountpoint -q /sys/kernel/debug; then
        mount -t debugfs debugfs /sys/kernel/debug || true
      fi

      if [ -f /var/lib/nbfc/state.json ]; then
        if ! jq -e '.TargetFanSpeeds | length == 2' /var/lib/nbfc/state.json >/dev/null 2>&1; then
          rm -f /var/lib/nbfc/state.json
        fi
      fi
    '';
    serviceConfig = {
      Type = "simple";
      ExecStart = "${nbfcLinux}/bin/nbfc_service --config-file /etc/nbfc/nbfc.json";
      Restart = "on-failure";
      RestartSec = 3;
      StateDirectory = "nbfc";
    };
  };
}
