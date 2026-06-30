{ lib, pkgs, ... }:

let
  asuraSuperProductivity = pkgs.writeShellScriptBin "asura-super-productivity" ''
    set -euo pipefail

    export ELECTRON_OZONE_PLATFORM_HINT="''${ELECTRON_OZONE_PLATFORM_HINT:-wayland}"
    exec ${pkgs.super-productivity}/bin/super-productivity \
      --ozone-platform=wayland \
      --enable-features=UseOzonePlatform,WaylandWindowDecorations \
      "$@"
  '';

  asuraSuperProductivityBridge = pkgs.writeShellScriptBin "asura-super-productivity-bridge" ''
    set -euo pipefail

    export PATH="${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.findutils
        pkgs.gh
        pkgs.gnugrep
        pkgs.gnused
        pkgs.jq
        pkgs.libnotify
        pkgs.procps
        pkgs.xdg-utils
      ]
    }:$PATH"

    data_home="''${XDG_DATA_HOME:-$HOME/.local/share}"
    notes_dir="$data_home/vibeshell-notes"
    notes_index="$notes_dir/index.json"
    export_dir="$data_home/vibeshell-integrations/super-productivity"
    export_json="$export_dir/vibeshell-notes-export.json"
    export_md="$export_dir/vibeshell-notes-export.md"

    notify() {
      notify-send -a asura-productivity "$@" --icon=super-productivity >/dev/null 2>&1 || true
    }

    ensure_notes_index() {
      mkdir -p "$notes_dir/notes" "$export_dir"
      if [ ! -s "$notes_index" ] || ! jq empty "$notes_index" 2>/dev/null; then
        printf '{"order":[],"notes":{}}\n' > "$notes_index"
      fi
    }

    html_to_text() {
      sed -E \
        -e 's/<br[[:space:]/]*>/\n/gI' \
        -e 's#</p>#\n\n#gI' \
        -e 's#</div>#\n#gI' \
        -e 's/<[^>]+>//g' \
        -e 's/&nbsp;/ /g' \
        -e 's/&amp;/\&/g' \
        -e 's/&lt;/</g' \
        -e 's/&gt;/>/g' \
        -e 's/&quot;/"/g' \
        -e "s/&apos;/'/g" \
        -e "s/&#39;/'/g"
    }

    export_notes() {
      ensure_notes_index
      exported_at="$(date -Iseconds)"

      jq \
        --arg exportedAt "$exported_at" \
        --arg notesDir "$notes_dir/notes" \
        '{
          source: "vibeshell-notes",
          target: "super-productivity",
          exportedAt: $exportedAt,
          importHint: "Bridge export. Configure GitHub issue sync inside Super Productivity with your own GitHub token.",
          notes: [
            (.order // [])[] as $id
            | ((.notes[$id] // {}) + {
                id: $id,
                htmlPath: ($notesDir + "/" + $id + ".html")
              })
          ]
        }' "$notes_index" > "$export_json.tmp"
      mv "$export_json.tmp" "$export_json"

      {
        printf '# VibeShell Notes export\n\n'
        printf 'Exported: %s\n\n' "$exported_at"
        jq -r '(.order // [])[] as $id | [$id, (.notes[$id].title // "Untitled"), (.notes[$id].modified // "")] | @tsv' "$notes_index" |
          while IFS=$'\t' read -r id title modified; do
            html_path="$notes_dir/notes/$id.html"
            printf '## %s\n\n' "$title"
            [ -n "$modified" ] && printf 'Modified: %s\n\n' "$modified"
            printf 'Source: `%s`\n\n' "$html_path"
            if [ -f "$html_path" ]; then
              html_to_text < "$html_path" | head -c 3000
              printf '\n\n'
            fi
          done
      } > "$export_md.tmp"
      mv "$export_md.tmp" "$export_md"

      notify "VibeShell notes exported" "$export_json"
      printf '%s\n' "$export_json"
    }

    status() {
      installed=true
      running=false
      github_connected=false
      last_export_path=""

      if pgrep -u "$(id -u)" -x 'super-productiv' >/dev/null 2>&1 || pgrep -u "$(id -u)" -f '/super-productivity( |$)' | grep -v 'bridge' >/dev/null 2>&1; then
        running=true
      fi
      if gh auth status -h github.com >/dev/null 2>&1; then
        github_connected=true
      fi
      if [ -s "$export_json" ]; then
        last_export_path="$export_json"
      fi

      jq -n \
        --argjson installed "$installed" \
        --argjson running "$running" \
        --argjson githubConnected "$github_connected" \
        --arg lastExportPath "$last_export_path" \
        '{
          installed: $installed,
          running: $running,
          githubConnected: $githubConnected,
          lastExportPath: $lastExportPath
        }'
    }

    github_setup() {
      xdg-open "https://github.com/settings/tokens/new?description=Super%20Productivity&scopes=repo,read:user" >/dev/null 2>&1 || true
      exec ${asuraSuperProductivity}/bin/asura-super-productivity
    }

    case "''${1:-status}" in
      status) status ;;
      open) exec ${asuraSuperProductivity}/bin/asura-super-productivity "''${@:2}" ;;
      github-setup) github_setup ;;
      export-notes) export_notes ;;
      export-open)
        export_notes >/dev/null
        xdg-open "$export_dir" >/dev/null 2>&1 || true
        ;;
      *)
        printf 'usage: asura-super-productivity-bridge [status|open|github-setup|export-notes|export-open]\n' >&2
        exit 64
        ;;
    esac
  '';
in
{
  inherit asuraSuperProductivity asuraSuperProductivityBridge;
}
