# PC-specific module: simple power status helpers for tuned-based ownership.
{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "power-status" ''
      set -euo pipefail

      echo "System power status"
      echo "==================="

      echo
      echo "CPU:"
      if [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
        echo "governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo unknown)"
        echo "current:  $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo unknown) kHz"
        echo "min:      $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null || echo unknown) kHz"
        echo "max:      $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null || echo unknown) kHz"
      else
        echo "cpufreq data unavailable"
      fi

      echo
      echo "Services:"
      systemctl is-active tuned >/dev/null 2>&1 && echo "tuned: active" || echo "tuned: inactive"
      systemctl is-active thermald >/dev/null 2>&1 && echo "thermald: active" || echo "thermald: inactive"
      systemctl is-active tlp >/dev/null 2>&1 && echo "tlp: active (unexpected)" || echo "tlp: inactive"

      if command -v tuned-adm >/dev/null 2>&1; then
        echo
        echo "Tuned profile:"
        tuned-adm active || true
      fi
    '')

    (pkgs.writeShellScriptBin "power-optimize" ''
      set -euo pipefail

      if command -v tuned-adm >/dev/null 2>&1; then
        sudo tuned-adm profile asura-pc-balanced \
          || sudo tuned-adm profile balanced \
          || true
      fi

      power-status
    '')
  ];
}
