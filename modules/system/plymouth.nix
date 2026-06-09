{ pkgs, ... }:
let
  theme = import ../../theme.nix;

  # Source NixOS snowflake logo (two two-tone lambdas, blue gradients).
  snowflakeSvg =
    "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";

  # Plymouth `script` plugin: centred, slowly breathing logo on a flat bg,
  # with any boot status text (fsck, prompts) shown subtly near the bottom.
  # `logo.png` is resolved relative to ImageDir, so no store paths here.
  scriptFile = pkgs.writeText "yugen-nix.script" ''
    # Flat background matching theme.nix `bg` (#151515).
    Window.SetBackgroundTopColor(0.082, 0.082, 0.082);
    Window.SetBackgroundBottomColor(0.082, 0.082, 0.082);

    screen_width  = Window.GetWidth();
    screen_height = Window.GetHeight();

    # --- centred logo ---
    logo.image  = Image("logo.png");
    logo.sprite = Sprite();
    logo.sprite.SetImage(logo.image);
    logo.sprite.SetX((screen_width  - logo.image.GetWidth())  / 2);
    logo.sprite.SetY((screen_height - logo.image.GetHeight()) / 2);
    logo.sprite.SetZ(10);

    # --- gentle breathing: opacity ~0.55..1.0, ~3.8s per cycle ---
    tick = 0;
    fun refresh_callback() {
      tick++;
      logo.sprite.SetOpacity(0.775 + 0.225 * Math.Sin(tick / 30));
    }
    Plymouth.SetRefreshFunction(refresh_callback);

    # --- subtle status line in a muted fg colour (theme.nix `fgMuted`) ---
    status.sprite = Sprite();
    fun message_callback(text) {
      status.image = Image.Text(text, 0.41, 0.41, 0.41);
      status.sprite.SetImage(status.image);
      status.sprite.SetX((screen_width - status.image.GetWidth()) / 2);
      status.sprite.SetY(screen_height * 0.86);
      status.sprite.SetZ(20);
    }
    Plymouth.SetMessageFunction(message_callback);
  '';

  # ---------------------------------------------------------------------------
  # Custom Plymouth theme: the NixOS snowflake recoloured into the Yugen/Ash
  # accent palette, breathing gently on the `bg` colour, then handing off
  # seamlessly to regreet. See modules/desktop/login.nix for the matching
  # login colours and theme.nix for the palette.
  # ---------------------------------------------------------------------------
  yugenNixTheme = pkgs.runCommand "yugen-nix-plymouth"
    {
      nativeBuildInputs = [ pkgs.librsvg ];
    }
    ''
      themeDir="$out/share/plymouth/themes/yugen-nix"
      mkdir -p "$themeDir"

      # Recolour the two blue lambda gradients into amber -> primary shades.
      # End stops come from theme.nix so the logo follows the palette; the two
      # mid stops are hand-picked shades along the same hue.
      cp ${snowflakeSvg} snowflake.svg
      sed -i \
        -e 's/#415e9a/#b8814a/gI' \
        -e 's/#4a6baf/#c69559/gI' \
        -e 's/#5277c3/${theme.amber}/gI' \
        -e 's/#699ad7/#e6a472/gI' \
        -e 's/#7eb1dd/#f2b17e/gI' \
        -e 's/#7ebae4/${theme.primary}/gI' \
        snowflake.svg

      rsvg-convert -w 400 snowflake.svg -o "$themeDir/logo.png"

      cp ${scriptFile} "$themeDir/yugen-nix.script"

      # Absolute paths here are rewritten into the initrd theme dir by the
      # NixOS plymouth module (it seds <store>/.../share/plymouth/themes).
      # Written flush-left: Plymouth's INI parser rejects leading whitespace.
      {
        printf '%s\n' '[Plymouth Theme]'
        printf '%s\n' 'Name=Yugen NixOS'
        printf '%s\n' 'Description=Breathing NixOS snowflake in the Yugen/Ash palette'
        printf '%s\n' 'ModuleName=script'
        printf '\n'
        printf '%s\n' '[script]'
        printf 'ImageDir=%s\n'  "$themeDir"
        printf 'ScriptFile=%s/yugen-nix.script\n' "$themeDir"
      } > "$themeDir/yugen-nix.plymouth"
    '';
in
{
  boot.plymouth = {
    enable = true;
    themePackages = [ yugenNixTheme ];
    theme = "yugen-nix";
  };

  # Load the Intel KMS driver in stage-1 initrd so the GPU is at native
  # resolution before Plymouth's first frame. Without this, Plymouth draws into
  # the low-res EFI/text framebuffer and only jumps to the real splash once
  # i915 loads mid-boot — which reads as the logo "loading slowly". (This is an
  # Intel Huawei Matebook; see hosts/qFioofa/hardware.nix.)
  boot.initrd.kernelModules = [ "i915" ];

  # Silence the kernel/systemd console spam so only the splash is visible.
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
    "vt.global_cursor_default=0"
    # NB: do NOT add `console=tty2` here. Plymouth derives the VT it renders the
    # splash on from the kernel `console=` parameter, but the foreground VT at
    # boot is always tty1 (where greetd also runs). `console=tty2` therefore
    # draws the splash onto an invisible VT, so the logo never appears. The
    # `quiet`/`loglevel`/`rd.*`/`udev.*` flags above (plus consoleLogLevel = 0
    # and initrd.verbose = false) already keep tty1 free of log spam, so the
    # whole splash -> greeter -> shutdown flow stays clean on tty1.
  ];

  # Hide the systemd-boot menu for a seamless firmware -> splash -> login flow.
  # Hold Space during boot to bring the menu back.
  boot.loader.timeout = 0;
}
