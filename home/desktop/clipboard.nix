{ config, pkgs, lib, ... }:
let
  # Screenshots. Every mode saves a PNG to ~/Pictures/Screenshots AND puts it on
  # the clipboard, then notifies. Modes:
  #   (none) — select a region, copy it straight away (the fast Lightshot path)
  #   edit   — select a region, open satty to annotate, then Enter/Ctrl+S copies
  #   full   — whole screen
  screenshot = pkgs.writeShellScriptBin "screenshot" ''
    export PATH="${lib.makeBinPath [ pkgs.grim pkgs.slurp pkgs.satty pkgs.wl-clipboard pkgs.libnotify pkgs.coreutils ]}:$PATH"
    dir="$HOME/Pictures/Screenshots"
    mkdir -p "$dir"
    img="$dir/screenshot-$(date +%Y-%m-%d-%H-%M-%S).png"
    case "''${1:-region}" in
      edit)
        sel=$(slurp) || exit 0
        grim -g "$sel" - | satty --filename - --output-filename "$img" \
          --copy-command wl-copy --early-exit --actions-on-enter save-to-clipboard exit
        ;;
      full)
        grim "$img"
        wl-copy < "$img"
        notify-send -i "$img" "Screenshot" "Full screen — copied to clipboard"
        ;;
      *)
        sel=$(slurp) || exit 0
        grim -g "$sel" "$img"
        wl-copy < "$img"
        notify-send -i "$img" "Screenshot" "Region — copied to clipboard"
        ;;
    esac
  '';

  # Dump whatever image is in the clipboard to a real file so the file manager
  # sees it — the Windows "paste into a folder" gesture, from the terminal.
  # `paste-image` -> timestamped file in cwd; `paste-image foo.png` -> that name.
  paste-image = pkgs.writeShellScriptBin "paste-image" ''
    export PATH="${lib.makeBinPath [ pkgs.wl-clipboard pkgs.coreutils pkgs.gnugrep ]}:$PATH"
    out="''${1:-pasted-$(date +%Y-%m-%d-%H-%M-%S).png}"
    case "$out" in /*) ;; *) out="$PWD/$out" ;; esac
    if wl-paste --list-types | grep -q '^image/'; then
      wl-paste --type image/png > "$out"
      echo "saved $out"
    else
      echo "no image in clipboard" >&2
      exit 1
    fi
  '';

  # cliphist history with image thumbnails in rofi — like Win+V. Binary entries
  # get decoded to a temp file and shown as their own icon; text stays text.
  clipboard-menu = pkgs.writeShellScriptBin "clipboard-menu" ''
    export PATH="${lib.makeBinPath [ pkgs.cliphist config.programs.rofi.finalPackage pkgs.wl-clipboard pkgs.coreutils ]}:$PATH"
    tmp="''${TMPDIR:-/tmp}/cliphist-thumbs"
    rm -rf "$tmp"; mkdir -p "$tmp"
    choice=$(
      cliphist list | while IFS= read -r line; do
        id="''${line%%$'\t'*}"
        case "$line" in
          *"[[ binary"*png*|*"[[ binary"*jpg*|*"[[ binary"*jpeg*|*"[[ binary"*bmp*|*"[[ binary"*webp*)
            ext=png
            case "$line" in *jpeg*|*jpg*) ext=jpg ;; esac
            f="$tmp/$id.$ext"
            cliphist decode "$id" > "$f"
            printf '%s\0icon\x1f%s\n' "$line" "$f"
            ;;
          *)
            printf '%s\n' "$line"
            ;;
        esac
      done | rofi -dmenu -show-icons -p Clipboard
    )
    [ -n "$choice" ] && printf '%s' "$choice" | cliphist decode | wl-copy
  '';
in
{
  home.packages = [ screenshot paste-image clipboard-menu pkgs.satty ];
}
