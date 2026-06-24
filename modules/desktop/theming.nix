# Shared module: system Stylix theme and cursor defaults.
{ pkgs, ... }:

{
  stylix = {
    enable = true;
    autoEnable = false;
    polarity = "dark";

    base16Scheme = ../../assets/gruvbox-dark-hard.yaml;

    image = pkgs.runCommand "gruvbox-wallpaper" { } ''
      mkdir -p $out
      ${pkgs.imagemagick}/bin/convert -size 1920x1080 xc:"#1d2021" $out/wallpaper.png
    '';

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Amber";
      size = 24;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = {
        package = pkgs.inter;
        name = "Inter";
      };
      sizes = {
        applications = 11;
        terminal = 13;
        desktop = 11;
        popups = 11;
      };
    };

    targets.gtk.enable = true;
  };

  nixpkgs.overlays = [
    (final: prev: {
      ags = prev.ags.overrideAttrs (old: {
        buildInputs = old.buildInputs ++ [
          pkgs.libdbusmenu-gtk3
          pkgs.ddcutil
        ];
      });
    })
    (final: prev: {
      pnpm_10 = prev.pnpm_10.overrideAttrs (old: {
        passthru = (old.passthru or { }) // {
          fetchDeps = args: final.fetchPnpmDeps (args // { pnpm = prev.pnpm_10; });
        };
      });
    })
  ];
}
