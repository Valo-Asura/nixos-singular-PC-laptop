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

  xdg.mimeApps = {
    defaultApplications = {
      "application/xhtml+xml" = "brave-browser.desktop";
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/about" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/unknown" = "brave-browser.desktop";
      "application/pdf" = "brave-browser.desktop";
    };
    associations.added = {
      "application/xhtml+xml" = "brave-browser.desktop";
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/about" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/unknown" = "brave-browser.desktop";
      "application/pdf" = "brave-browser.desktop";
    };
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
