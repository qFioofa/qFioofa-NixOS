{ pkgs, ... }:
let
  theme = import ../../theme.nix;

  # Source NixOS snowflake logo (two two-tone lambdas, blue gradients).
  snowflakeSvg =
    "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";

  # A single soft ring, recoloured to the `tide` water hue. The script scales
  # this one image up over time to fake expanding ripples, so only one asset is
  # needed regardless of how many concurrent rings are drawn.
  rippleSvg = pkgs.writeText "ripple.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" width="240" height="240" viewBox="0 0 240 240">
      <circle cx="120" cy="120" r="112" fill="none" stroke="${theme.tide}" stroke-width="5"/>
    </svg>
  '';

  # Plymouth `script` plugin: a centred logo that breathes gently while soft
  # rings ripple outward from behind it, like a drop landing on still water.
  # Image names ("logo.png", "ripple.png") resolve relative to ImageDir.
  scriptFile = pkgs.writeText "yugen-nix.script" ''
    # Flat background matching theme.nix `bg` (#151515).
    Window.SetBackgroundTopColor(0.082, 0.082, 0.082);
    Window.SetBackgroundBottomColor(0.082, 0.082, 0.082);

    screen_width  = Window.GetWidth();
    screen_height = Window.GetHeight();

    # --- centred logo (drawn above the ripples) ---
    logo.image  = Image("logo.png");
    logo.sprite = Sprite();
    logo.sprite.SetImage(logo.image);
    logo.sprite.SetX((screen_width  - logo.image.GetWidth())  / 2);
    logo.sprite.SetY((screen_height - logo.image.GetHeight()) / 2);
    logo.sprite.SetZ(10);

    # --- water ripples: one ring image, scaled up across several staggered
    #     sprites so a new ring sets off roughly every second ---
    ring_image = Image("ripple.png");
    ring_w = ring_image.GetWidth();
    ring_h = ring_image.GetHeight();

    count  = 4;                 # concurrent rings
    period = 55;                # ticks between launches (~1.1s at 50Hz)
    life   = count * period;    # ticks a ring lives before it recycles

    for (i = 0; i < count; i++) {
      ring[i] = Sprite();
      ring[i].SetZ(5);          # behind the logo (Z=10)
      age[i] = i * period;      # evenly staggered phases
    }

    tick = 0;
    fun refresh_callback() {
      tick = tick + 1;

      # Soft breathing of the logo, ~4.5s per cycle.
      logo.sprite.SetOpacity(0.82 + 0.18 * Math.Sin(tick / 36));

      for (i = 0; i < count; i++) {
        age[i] = age[i] + 1;
        if (age[i] >= life) { age[i] = 0; }

        t = age[i] / life;                 # 0 .. 1 progress
        scale = 0.30 + 1.70 * t;           # grow outward from the centre
        w = ring_w * scale;
        h = ring_h * scale;

        scaled = ring_image.Scale(w, h);
        ring[i].SetImage(scaled);
        ring[i].SetX((screen_width  - w) / 2);
        ring[i].SetY((screen_height - h) / 2);
        # Rise then fall — soft, peaks mid-life and never harsh.
        ring[i].SetOpacity(0.40 * Math.Sin(t * 3.14159265));
      }
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
  # Custom Plymouth theme: the NixOS snowflake recoloured from its stock blues
  # into a cool "water" teal gradient (theme.nix `tide`), keeping `primary` as
  # the single warm accent highlight, rippling gently on the `bg` colour before
  # handing off to regreet. See modules/desktop/login.nix for matching colours.
  # ---------------------------------------------------------------------------
  yugenNixTheme = pkgs.runCommand "yugen-nix-plymouth"
    {
      nativeBuildInputs = [ pkgs.librsvg ];
    }
    ''
      themeDir="$out/share/plymouth/themes/yugen-nix"
      mkdir -p "$themeDir"

      # Recolour the two blue lambda gradients into a teal water ramp (dark ->
      # light), with the brightest stop kept as the warm `primary` accent so the
      # logo still carries the palette's signature highlight.
      cp ${snowflakeSvg} snowflake.svg
      sed -i \
        -e 's/#415e9a/#243f47/gI' \
        -e 's/#4a6baf/#305058/gI' \
        -e 's/#5277c3/#436a73/gI' \
        -e 's/#699ad7/${theme.tide}/gI' \
        -e 's/#7eb1dd/#a6c5cc/gI' \
        -e 's/#7ebae4/${theme.primary}/gI' \
        snowflake.svg

      rsvg-convert -w 400 snowflake.svg     -o "$themeDir/logo.png"
      rsvg-convert -w 240 ${rippleSvg}      -o "$themeDir/ripple.png"

      cp ${scriptFile} "$themeDir/yugen-nix.script"

      # Absolute paths here are rewritten into the initrd theme dir by the
      # NixOS plymouth module (it seds <store>/.../share/plymouth/themes).
      # Written flush-left: Plymouth's INI parser rejects leading whitespace.
      {
        printf '%s\n' '[Plymouth Theme]'
        printf '%s\n' 'Name=Yugen NixOS'
        printf '%s\n' 'Description=Rippling NixOS snowflake in the Yugen/Ash water palette'
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
