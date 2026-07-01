{ config, pkgs, lib, ... }:
let
  # Lightshot-style: select a region, annotate (arrow/text/rect/highlight/blur),
  # then Enter copies to clipboard, Ctrl+S saves a PNG to ~/Pictures/Screenshots.
  # Satty is the editor; grim+slurp do the region grab.
  screenshot = pkgs.writeShellScriptBin "screenshot" ''
    export PATH="${lib.makeBinPath [ pkgs.grim pkgs.slurp pkgs.satty pkgs.wl-clipboard pkgs.coreutils ]}:$PATH"
    dir="$HOME/Pictures/Screenshots"
    mkdir -p "$dir"
    sel=$(slurp) || exit 0
    grim -g "$sel" - | satty --filename - \
      --output-filename "$dir/screenshot-$(date +%Y-%m-%d-%H-%M-%S).png" \
      --copy-command wl-copy \
      --early-exit \
      --actions-on-enter save-to-clipboard exit
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
