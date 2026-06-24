# Chromium Browser Theming, XDM Integration, and Thumbnail Support
{ pkgs, ... }:

let
  xdmExtensionPath = "/opt/xdman/chrome-extension";
  chromiumManagedPolicy = ''
    {
      "RestoreOnStartup": 1,
      "ExtensionInstallSources": [
        "file://${xdmExtensionPath}/*"
      ],
      "ExtensionSettings": {
        "*": {
          "installation_mode": "allowed"
        }
      }
    }
  '';
in
{
  environment.sessionVariables = {
    MOZ_USE_XINPUT2 = "1";
    CHROME_EXECUTABLE = "${pkgs.google-chrome}/bin/google-chrome-stable";
  };

  systemd.tmpfiles.rules = [
    # Antigravity's browser launcher ignores CHROME_PATH and probes hardcoded
    # Linux paths. Keep these compatibility links declarative.
    "L+ /usr/bin/google-chrome - - - - ${pkgs.google-chrome}/bin/google-chrome-stable"
    "L+ /usr/bin/google-chrome-stable - - - - ${pkgs.google-chrome}/bin/google-chrome-stable"
    "L+ /usr/bin/chromium - - - - ${pkgs.chromium}/bin/chromium"
    "L+ /usr/bin/chromium-browser - - - - ${pkgs.chromium}/bin/chromium"
    "d /home/asura/.cache 0755 asura users -"
    "d /home/asura/.cache/thumbnails 0755 asura users -"
    "d /home/asura/.cache/thumbnails/normal 0755 asura users -"
    "d /home/asura/.cache/thumbnails/large 0755 asura users -"
    "d /home/asura/.cache/thumbnails/fail 0755 asura users -"
    "Z /home/asura/.cache/thumbnails 0755 asura users - -"
  ];

  environment.etc = {
    "opt/chrome/policies/managed/asura-xdm-integration.json".text = chromiumManagedPolicy;

    "chromium/policies/managed/asura-xdm-integration.json".text = chromiumManagedPolicy;

    "brave/policies/managed/asura-xdm-integration.json".text = chromiumManagedPolicy;

    "helium/policies/managed/asura-xdm-integration.json".text = chromiumManagedPolicy;
  };

  environment.systemPackages = with pkgs; [
    ffmpegthumbnailer
    poppler-utils
    libgsf
    shared-mime-info
    desktop-file-utils
  ];

  services.tumbler.enable = true;
}
