# Chrome and Chromium XDM integration.
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
  home.packages = [
    pkgs.google-chrome
  ];

  xdg.desktopEntries.google-chrome = {
    name = "Google Chrome";
    genericName = "Web Browser";
    exec = "env GTK_USE_PORTAL=1 ${pkgs.google-chrome}/bin/google-chrome-stable --load-extension=${xdmExtensionPath} %U";
    icon = "google-chrome";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = browserMimeTypes;
    settings.StartupWMClass = "google-chrome";
  };

  xdg.desktopEntries.chromium-browser = {
    name = "Chromium";
    genericName = "Web Browser";
    exec = "env GTK_USE_PORTAL=1 ${pkgs.chromium}/bin/chromium --load-extension=${xdmExtensionPath} %U";
    icon = "chromium";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = browserMimeTypes;
    settings.StartupWMClass = "chromium-browser";
  };

  xdg.configFile."google-chrome/policies/managed/xdm-integration.json".text = chromiumPolicy;
  xdg.configFile."chromium/policies/managed/xdm-integration.json".text = chromiumPolicy;
}
