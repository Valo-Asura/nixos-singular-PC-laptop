# Firefox policy and theme defaults.
{ ... }:

{
  programs.firefox = {
    enable = true;
    # Keep the pre-26.05 profile path explicit for this existing install.
    configPath = ".mozilla/firefox";
    policies.ExtensionSettings = {
      "uBlock0@raymondhill.net" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        installation_mode = "force_installed";
        default_area = "menupanel";
        private_browsing = true;
      };
      # XDM 8.x uses the v8 helper. The older browser-mon@xdman add-on still
      # installs from AMO, but it does not talk to the 8.x localhost monitor
      # reliably and creates a duplicate extension in Firefox.
      "browser-mon@xdman.sourceforge.net" = {
        installation_mode = "blocked";
      };
      "xdm-v8-browser-helper@subhra74.github.io" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/file/4095144/xdm_browser_monitor_v8-3.4.xpi";
        installation_mode = "force_installed";
        default_area = "menupanel";
        private_browsing = true;
      };
    };

    profiles.default = {
      settings = {
        "ui.systemUsesDarkTheme" = 1;
        "browser.theme.content-theme" = 0;
        "browser.theme.toolbar-theme" = 0;
        "devtools.theme" = "dark";
        "widget.content.allow-gtk-dark-theme" = true;
        "layout.css.prefers-color-scheme.content-override" = 0;
        "browser.display.use_system_colors" = true;
        "browser.anchor_color" = "#0096ff";
        "browser.visited_color" = "#ff00ff";
        "privacy.trackingprotection.enabled" = true;
        "dom.security.https_only_mode" = true;
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "browser.cache.disk.enable" = true;
        "browser.startup.page" = 3;
        "browser.sessionstore.resume_from_crash" = true;
      };

      userChrome = ''
        @namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");

        :root {
          --toolbar-bgcolor: #1d2021 !important;
          --toolbar-color: #ebdbb2 !important;
          --lwt-accent-color: #1d2021 !important;
          --lwt-text-color: #ebdbb2 !important;
        }

        #nav-bar, #PersonalToolbar, #TabsToolbar {
          background-color: #1d2021 !important;
          color: #ebdbb2 !important;
        }

        .tabbrowser-tab {
          background-color: #282828 !important;
          color: #ebdbb2 !important;
        }

        .tabbrowser-tab[selected="true"] {
          background-color: #3c3836 !important;
          color: #fbf1c7 !important;
        }
      '';

      userContent = ''
        @-moz-document url-prefix(about:) {
          body {
            background-color: #1d2021 !important;
            color: #ebdbb2 !important;
          }
        }

        * {
          scrollbar-color: #504945 #282828 !important;
        }
      '';
    };
  };
}
