# Program configurations
{ pkgs, ... }:

{
  imports = [
    ./git
    ./terminal
    # ./neovim
    ./tmux
    # ./fastfetch
    ./scripts
  ];
}
