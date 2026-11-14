{ config, lib, pkgs, ... }:
let
  cfg = config.hardware.huawei.matebook;

  sofEs8336TglTplgCompat = pkgs.runCommand "sof-tgl-es8336-tplg-compat"
    { passthru.compressFirmware = false; } ''
      d="$out/lib/firmware/intel/sof-tplg"
      src="${pkgs.sof-firmware}/lib/firmware/intel/sof-tplg"
      mkdir -p "$d"
      ln -s "$src/sof-tgl-es8336-dmic2ch-ssp0.tplg" "$d/sof-tgl-es8336-dmic2ch.tplg"
      ln -s "$src/sof-tgl-es8336-dmic4ch-ssp0.tplg" "$d/sof-tgl-es8336-dmic4ch.tplg"
    '';

  avsFirmwarePackage =
    if cfg.avsFirmware == null then null else
    pkgs.runCommand "huawei-avs-tgl-firmware" { } ''
      mkdir -p "$out/lib/firmware/intel/avs/tgl"
      cp ${builtins.path {
        path = cfg.avsFirmware;
        name = "dsp_basefw.bin";
      }} "$out/lib/firmware/intel/avs/tgl/dsp_basefw.bin"
    '';
in
{
  options.hardware.huawei.matebook = {
    enable = lib.mkEnableOption
      "Huawei Matebook hardware quirk fixes (Dummy Output audio, dead internal mic, IPU6 camera)";

    audioDriver = lib.mkOption {
      type = lib.types.enum [ "sof" "hda" "avs" ];
      default = "hda";
      description = ''
        Which Intel DSP driver to force for the built-in audio:
          - "sof"  Force the SOF DSP (dsp_driver=3). Needed by Matebooks that
                   keep the internal mic on the DSP as a digital mic (DMIC),
                   which legacy HDA cannot expose.
          - "avs"  Force the AVS DSP (dsp_driver=4) with a Huawei AVS base
                   firmware (see avsFirmware). This is the Ubuntu-era workaround
                   for BOD-WXX9 units whose ES8336 sits on a firmware-disabled
                   I2C bus: AVS drives the SN6140 codec and the internal DMIC
                   directly, without needing the dead ES8336/I2C2 link.
          - "hda"  Force legacy HDA (dsp_driver=1) plus snd-hda-intel
                   dmic_detect=0. Only for models whose speakers/mic sit on a
                   plain HDA codec (e.g. Conexant/Realtek) and that genuinely
                   misbehave under SOF. Do NOT use it on the I2C-codec models
                   (ES8336 etc.): HDA cannot drive an I2C codec, so it produces
                   no working card — those need "sof" or "avs".
      '';
    };

    avsFirmware = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.path lib.types.str);
      default = null;
      example = "./firmware/dsp_fw_release.bin";
      description = ''
        Path to the Tiger Lake AVS base firmware (`dsp_fw_release.bin`)
        extracted from Huawei's Windows ISST package
        (Fw/dsp_fw_release.bin inside HUAWEI_Matebook_D_15_2022_ISST_*.zip).
        It is installed as intel/avs/tgl/dsp_basefw.bin.

        Required when audioDriver = "avs". This blob is not shipped by
        linux-firmware: without it AVS cannot boot the DSP, so the internal
        DMIC stays silent. Because it is proprietary Huawei/Intel firmware,
        use a path inside the flake (tracked by git, e.g.
        ./firmware/dsp_fw_release.bin) or rebuild with `--impure` when pointing
        at an absolute path outside the repository.
      '';
    };

    micFix = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable the Conexant SN6140 analog capture path with hda-verb — the
        microphone half of the Ubuntu "ESSX8336 ACPI ghost" workaround for
        BOD-WXX9. The generic HDA parser leaves the Mic pin biased at VREF_HIZ
        and its input amp muted, so the card exists but records silence. Only
        applied when audioDriver = "hda". This fixes the analog/headset mic;
        the internal DMIC is a separate DSP path and needs audioDriver = "avs".
      '';
    };

    es8336Quirk = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = 384; # 0x180 = HEADPHONE_GPIO | HEADSET_MIC1, SSP codec 0
      description = ''
        Quirk bitmask passed to the SOF ES8336 machine driver
        (`options snd_soc_sof_es8336 quirk=…`), only used when
        audioDriver = "sof". It encodes how the ES8336 is wired on this board:

          bits 0-3  SSP codec port number          (0 for Matebook D → SSP0)
          BIT(4) 16 SPEAKERS_EN_GPIO1
          BIT(5) 32 ENABLE_DMIC
          BIT(6) 64 JD_INVERTED  (jack-detect polarity)
          BIT(7) 128 HEADPHONE_GPIO (separate GPIO mutes speakers on plug-in)
          BIT(8) 256 HEADSET_MIC1   (internal/headset mic on MIC1)

        The default 384 (0x180) matches the in-tree Huawei Matebook D ES8336
        entry (and the BOD-WXX9 quirk): SSP0, separate headphone GPIO, headset
        mic on MIC1. Speakers already work from just the topology shim; this
        adds correct headphone-jack switching. Set to null to let the kernel /
        NHLT decide with no override.
      '';
    };

    ipu6Platform = lib.mkOption {
      type = lib.types.enum [ "ipu6" "ipu6ep" "ipu6epmtl" "none" ];
      default = "ipu6ep";
      description = ''
        Intel IPU6 MIPI camera platform for the built-in webcam:
          - "ipu6"      Tiger Lake
          - "ipu6ep"    Alder Lake / Raptor Lake (most 2022-2023 Matebooks)
          - "ipu6epmtl" Meteor Lake (2024+ Matebooks)
          - "none"      laptop has a normal USB/UVC webcam; skip the IPU6 stack
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.audioDriver != "avs" || cfg.avsFirmware != null;
        message = ''
          hardware.huawei.matebook.avsFirmware must be set to the extracted
          dsp_fw_release.bin when audioDriver = "avs".
        '';
      }
    ];

    # --- Audio: Dummy Output / dead internal microphone -----------------------
    # The internal mic on these Matebooks sits on the Intel DSP, and which DSP
    # driver works is model-dependent (see the audioDriver option):
    #
    #   "sof"  Force the SOF DSP (dsp_driver=3). Exposes both the codec
    #          (speakers/headphones) and the internal digital mic (DMIC) on
    #          models that keep the mic on the DSP. dmic_detect must NOT be set
    #          here — it is a legacy-HDA-only option, irrelevant once SOF owns
    #          the device.
    #
    #   "avs"  Force the AVS DSP (dsp_driver=4). Same idea as SOF, but AVS does
    #          not go through the ES8336 machine driver, so it still works when
    #          the ES8336 I2C bus is firmware-disabled (BOD-WXX9). Needs the
    #          Huawei dsp_fw_release.bin (avsFirmware): linux-firmware has no
    #          Tiger Lake AVS base firmware.
    #
    #   "hda"  Force legacy HDA (dsp_driver=1) for models whose audio is a plain
    #          HDA codec (Conexant/Realtek) and that misbehave under SOF. Legacy
    #          HDA gives speakers and the analog/headset mic; dmic_detect=0 stops
    #          a broken DMIC probe from poisoning the card. NOTE: this does NOT
    #          work for I2C-codec models (ES8336): HDA can't drive an I2C codec,
    #          so it registers no usable card and you get the silent "Dummy
    #          Output" — use "sof" or "avs" there instead.
    boot.extraModprobeConfig =
      if cfg.audioDriver == "sof" then ''
        options snd-intel-dspcfg dsp_driver=3
      '' + lib.optionalString (cfg.es8336Quirk != null) ''
        options snd_soc_sof_es8336 quirk=${toString cfg.es8336Quirk}
      '' else if cfg.audioDriver == "avs" then ''
        options snd-intel-dspcfg dsp_driver=4
      '' else ''
        options snd-intel-dspcfg dsp_driver=1
        options snd-hda-intel dmic_detect=0
      '';

    # SOF firmware is only used by the DSP path, but it is small and harmless to
    # ship unconditionally, so the audioDriver toggle stays self-contained. The
    # compat shim supplies the bare-named TGL ES8336 topology the kernel asks for
    # (see sofEs8336TglTplgCompat above) and is only needed under SOF. AVS uses
    # its own topologies from linux-firmware plus the Huawei base firmware.
    hardware.firmware = [ pkgs.sof-firmware ]
      ++ lib.optional (cfg.audioDriver == "sof") sofEs8336TglTplgCompat
      ++ lib.optional (cfg.audioDriver == "avs" && cfg.avsFirmware != null)
        avsFirmwarePackage;

    # --- Microphone: analog capture path on the Conexant codec ----------------
    # Ubuntu's fix for BOD-WXX9 units (the ESSX8336 "ACPI ghost" workaround)
    # does not just switch to HDA: it also re-biases the Mic pin and unmutes the
    # input amp with hda-verb. The generic HDA parser leaves them at VREF_HIZ /
    # muted, so the capture device shows up but records only silence. The
    # commands below mirror that fix (node 0x19 = Mic pin, node 0x13 = input
    # converter/mux on the SN6140).
    systemd.services.huawei-mic-fix = lib.mkIf (cfg.audioDriver == "hda" && cfg.micFix) {
      description = "Enable Huawei Matebook Conexant SN6140 analog microphone";
      wantedBy = [ "multi-user.target" ];
      wants = [ "sound.target" ];
      after = [ "sound.target" ];
      path = [ pkgs.coreutils pkgs.gnused pkgs.alsa-tools pkgs.alsa-utils ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # The HDA card can appear a little after sound.target; wait for its
        # codec hwdep node instead of racing udev.
        card=
        hw=
        i=0
        while [ "$i" -lt 30 ]; do
          card=$(sed -n 's/^ *\([0-9]\+\) \[.*/\1/p' /proc/asound/cards 2>/dev/null | head -n1)
          if [ -n "$card" ] && [ -e "/dev/snd/hwC''${card}D0" ]; then
            hw="/dev/snd/hwC''${card}D0"
            break
          fi
          i=$((i + 1))
          sleep 1
        done

        if [ -z "$hw" ]; then
          echo "HDA codec hwdep not found; skipping microphone fix"
          exit 0
        fi

        # Pin 0x19: input + VREF 80 so the microphone gets bias.
        hda-verb "$hw" 0x19 0x707 0x24 || true
        # Converter 0x13: select node 0x19 and unmute its input amp (gain 0x50).
        hda-verb "$hw" 0x13 0x701 0x1 || true
        hda-verb "$hw" 0x13 0x3b0 0x50 || true

        # Keep the userspace mixer consistent with the verbs above.
        amixer -c "$card" sset Capture 100% unmute || true
        amixer -c "$card" sset 'Mic Boost' 2 || true
      '';
    };

    # --- Microphone: internal DMIC through AVS --------------------------------
    # AVS exposes the internal digital mic as a separate "DMIC" card. Its gain
    # defaults to 0, which looks like a dead mic, so bring it up once the card
    # registers.
    systemd.services.huawei-avs-mic-gain = lib.mkIf (cfg.audioDriver == "avs") {
      description = "Set Huawei Matebook AVS DMIC capture gain";
      wantedBy = [ "multi-user.target" ];
      wants = [ "sound.target" ];
      after = [ "sound.target" ];
      path = [ pkgs.coreutils pkgs.alsa-utils ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        i=0
        while [ "$i" -lt 30 ]; do
          if amixer -c DMIC sset DMIC 100% unmute >/dev/null 2>&1; then
            exit 0
          fi
          i=$((i + 1))
          sleep 1
        done
        echo "AVS DMIC card not found; skipping gain setup"
      '';
    };

    # Re-apply the hardware state after resume; the HDA/AVS codec can reset the
    # pin bias and amp values across suspend.
    powerManagement.resumeCommands = lib.optionalString
      (cfg.audioDriver == "hda" && cfg.micFix)
      "systemctl restart huawei-mic-fix.service"
      + lib.optionalString (cfg.audioDriver == "avs")
      "systemctl restart huawei-avs-mic-gain.service";

    # --- Camera: Intel IPU6 MIPI webcam (no /dev/video*, black image) ---------
    # Recent Matebooks (X Pro, 14s, D16 2024…) use an Intel IPU6 MIPI sensor
    # rather than a USB UVC cam, so nothing appears until the IPU6 stack and its
    # v4l2 relay are running. Skipped entirely when ipu6Platform = "none".
    hardware.ipu6 = lib.mkIf (cfg.ipu6Platform != "none") {
      enable = true;
      platform = cfg.ipu6Platform;
    };
  };
}
