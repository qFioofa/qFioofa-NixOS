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
in
{
  options.hardware.huawei.matebook = {
    enable = lib.mkEnableOption
      "Huawei Matebook hardware quirk fixes (Dummy Output audio, dead internal mic, IPU6 camera)";

    audioDriver = lib.mkOption {
      type = lib.types.enum [ "sof" "hda" ];
      default = "hda";
      description = ''
        Which Intel DSP driver to force for the built-in audio:
          - "sof"  Force the SOF DSP (dsp_driver=3). Needed by Matebooks that
                   keep the internal mic on the DSP as a digital mic (DMIC),
                   which legacy HDA cannot expose.
          - "hda"  Force legacy HDA (dsp_driver=1) plus snd-hda-intel
                   dmic_detect=0. Only for models whose speakers/mic sit on a
                   plain HDA codec (e.g. Conexant/Realtek) and that genuinely
                   misbehave under SOF. Do NOT use it on the I2C-codec models
                   (ES8336 etc.): HDA cannot drive an I2C codec, so it produces
                   no working card — those need "sof".
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
    #   "hda"  Force legacy HDA (dsp_driver=1) for models whose audio is a plain
    #          HDA codec (Conexant/Realtek) and that misbehave under SOF. Legacy
    #          HDA gives speakers and the analog/headset mic; dmic_detect=0 stops
    #          a broken DMIC probe from poisoning the card. NOTE: this does NOT
    #          work for I2C-codec models (ES8336): HDA can't drive an I2C codec,
    #          so it registers no usable card and you get the silent "Dummy
    #          Output" — use "sof" there instead.
    boot.extraModprobeConfig =
      if cfg.audioDriver == "sof" then ''
        options snd-intel-dspcfg dsp_driver=3
      '' + lib.optionalString (cfg.es8336Quirk != null) ''
        options snd_soc_sof_es8336 quirk=${toString cfg.es8336Quirk}
      '' else ''
        options snd-intel-dspcfg dsp_driver=1
        options snd-hda-intel dmic_detect=0
      '';

    # SOF firmware is only used by the DSP path, but it is small and harmless to
    # ship unconditionally, so the audioDriver toggle stays self-contained. The
    # compat shim supplies the bare-named TGL ES8336 topology the kernel asks for
    # (see sofEs8336TglTplgCompat above) and is only needed under SOF.
    hardware.firmware = [ pkgs.sof-firmware ]
      ++ lib.optional (cfg.audioDriver == "sof") sofEs8336TglTplgCompat;

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
