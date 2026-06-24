# Laptop-specific module: XS15 declarative active shell choice.
{
  config,
  lib,
  ...
}:

{
  options.asura.shell.active = lib.mkOption {
    type = lib.types.enum [
      "waybar"
      "noctalia"
      "vibeshell"
    ];
    default = "noctalia";
    description = "Active desktop shell for this host. Supported: waybar, noctalia, vibeshell.";
  };

  config.environment.etc."asura-shell/active-shell".text = ''
    ${config.asura.shell.active}
  '';
}
