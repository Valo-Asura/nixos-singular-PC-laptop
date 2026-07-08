if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

set -e ELECTRON_RUN_AS_NODE
set -gx BROWSER firefox
fish_add_path -g ~/.local/bin ~/.local/opt/cursor ~/.local/opt/antigravity ~/.local/opt/antigravity-ide

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

starship init fish | source

# Custom Fastfetch Alias & Greeting
alias fastfetch="fastfetch --processing-timeout 200 -c ~/.config/fastfetch/config.jsonc"
alias ff="fastfetch"

function fish_greeting
    test "$ASURA_SKIP_FASTFETCH" = "1"; and return
    fastfetch
end

string match -q "$TERM_PROGRAM" "kiro" and . (kiro --locate-shell-integration-path fish)

# Codex and AI Memory Aliases
alias cm="codex-mem"
alias am="asura-ai-memory"
alias cmg="codex-mem goals"
alias cmt="codex-mem threads"
alias cml="codex-mem logs"
alias cms="codex-mem raw-search"

# NixOS maintenance aliases. Noctalia owns fish/config.fish, so mirror the
# Home Manager shell aliases here for the active terminal profile.
alias rebuild="nixos-rebuild-safe switch --flake /etc/nixos#asura-xs15"
alias lrb="nixos-rebuild-safe switch --flake /etc/nixos#asura-xs15"
alias prb="nixos-rebuild-safe switch --flake /etc/nixos#asura-pc"
alias update="nix flake update --flake /etc/nixos"
alias lup="nix flake update --flake /etc/nixos && nixos-rebuild-safe switch --flake /etc/nixos#asura-xs15"
alias pup="nix flake update --flake /etc/nixos && nixos-rebuild-safe switch --flake /etc/nixos#asura-pc"
alias clean="/run/wrappers/bin/sudo nix-collect-garbage -d"
alias clean-store="nix-storage-clean"

# Start tmux explicitly with `tmux`. Avoid auto-exec so Foot opens instantly.
