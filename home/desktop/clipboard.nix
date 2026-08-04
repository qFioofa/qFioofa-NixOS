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
          --copy-command "wl-copy --type image/png" --early-exit --actions-on-enter save-to-clipboard exit
        ;;
      full)
        grim "$img"
        wl-copy --type image/png < "$img"
        notify-send -i "$img" "Screenshot" "Full screen — copied to clipboard"
        ;;
      *)
        sel=$(slurp) || exit 0
        grim -g "$sel" "$img"
        wl-copy --type image/png < "$img"
        notify-send -i "$img" "Screenshot" "Region — copied to clipboard"
        ;;
    esac
  '';

  # Dump whatever image is in the clipboard to a real file so the file manager
  # sees it — the Windows "paste into a folder" gesture. Nemo (like most Linux
  # file managers) can't paste raw clipboard image data itself; the Nemo action
  # below calls this with %P (the open folder). Arg can be a dir (timestamped
  # file inside it), a filename, or omitted (timestamped in cwd). notify-send so
  # there's feedback when run from the file manager with no terminal attached.
  paste-image = pkgs.writeShellScriptBin "paste-image" ''
    export PATH="${lib.makeBinPath [ pkgs.wl-clipboard pkgs.coreutils pkgs.gnugrep pkgs.libnotify ]}:$PATH"
    arg="''${1:-$PWD}"
    if [ -d "$arg" ]; then
      out="$arg/pasted-$(date +%Y-%m-%d-%H-%M-%S).png"
    else
      case "$arg" in /*) out="$arg" ;; *) out="$PWD/$arg" ;; esac
    fi
    if wl-paste --list-types | grep -q '^image/'; then
      wl-paste --type image/png > "$out"
      notify-send -i "$out" "Clipboard" "Saved image to $out"
      echo "saved $out"
    else
      notify-send "Clipboard" "No image in clipboard"
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

  # Right-click on empty space in Nemo → "Paste image from clipboard". %P is the
  # currently open folder. Selection=none makes it a background-menu item.
  xdg.dataFile."nemo/actions/paste-image.nemo_action".text = ''
    [Nemo Action]
    Name=Paste image from clipboard
    Comment=Save the clipboard image into this folder
    Exec=${config.home.profileDirectory}/bin/paste-image %P
    Icon-Name=insert-image
    Selection=none
    Extensions=any;
  '';
}
