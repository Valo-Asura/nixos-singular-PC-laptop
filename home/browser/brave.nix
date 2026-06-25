# Brave defaults, XDM integration, and browser MIME ownership.
{ pkgs, ... }:

let
  xdmExtensionPath = "/opt/xdman/chrome-extension";
  browserMimeTypes = [
    "application/xhtml+xml"
    "text/html"
    "x-scheme-handler/about"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/unknown"
  ];
  chromiumPolicy = ''
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
  programs.brave = {
    enable = true;
    commandLineArgs = [
      "--load-extension=${xdmExtensionPath}"
    ];
  };

  xdg.desktopEntries.brave-browser = {
    name = "Brave Web Browser";
    genericName = "Web Browser";
    exec = "env GTK_USE_PORTAL=1 ${pkgs.brave}/bin/brave --load-extension=${xdmExtensionPath} %U";
    icon = "brave-browser";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = browserMimeTypes;
    settings.StartupWMClass = "brave-browser";
  };

  xdg.configFile."BraveSoftware/Brave-Browser/policies/managed/xdm-integration.json".text =
    chromiumPolicy;
}
