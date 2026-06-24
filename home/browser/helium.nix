# Helium browser session and XDM integration.
{ ... }:

let
  xdmExtensionPath = "/opt/xdman/chrome-extension";
  browserMimeTypes = [
    "application/pdf"
    "application/rdf+xml"
    "application/rss+xml"
    "application/xhtml+xml"
    "application/xml"
    "image/gif"
    "image/jpeg"
    "image/png"
    "image/webp"
    "text/html"
    "text/xml"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
  ];
in
{
  xdg.configFile."helium/policies/managed/session-restore.json".text = ''
    {
      "RestoreOnStartup": 1
    }
  '';

  xdg.desktopEntries.helium = {
    name = "Helium";
    genericName = "Web Browser";
    exec = "env GTK_USE_PORTAL=1 helium --load-extension=${xdmExtensionPath} %U";
    icon = "helium";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = browserMimeTypes;
    settings.StartupWMClass = "helium";
  };
}
