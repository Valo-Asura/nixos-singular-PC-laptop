# Helium browser session policy.
{ ... }:

{
  xdg.configFile."helium/policies/managed/session-restore.json".text = ''
    {
      "RestoreOnStartup": 1
    }
  '';
}
