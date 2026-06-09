{ config, lib, pkgs, ... }:
let
  cfg = config.hardware.huawei.matebook;
in
{
  options.hardware.huawei.matebook = {
    enable = lib.mkEnableOption
      "Huawei Matebook hardware quirk fixes (Dummy Output audio, dead internal mic, IPU6 camera)";

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
    # --- Audio: dead internal microphone (DMIC) -------------------------------
    # This Matebook (Tiger Lake, Conexant SN6140 codec, NHLT/DMIC in ACPI) keeps
    # its built-in microphone on the Intel DSP as a digital mic (DMIC). The
    # legacy HDA driver (snd-hda-intel) cannot expose a DMIC, so under dsp_driver=1
    # only the external headset-jack mic enumerates and the internal mic is dead.
    # Forcing the SOF driver (dsp_driver=3) brings up the DSP audio path, which
    # exposes both the codec (speakers/headphones) and the internal DMIC.
    #
    # dmic_detect is a legacy-HDA-only option and must NOT be set here: it would
    # only suppress mic detection, and it is irrelevant once SOF owns the device.
    #
    # NOTE: a minority of Matebook models are the inverse — forcing SOF leaves
    # them with a silent "Dummy Output". If audio is dead after this, fall back to
    # dsp_driver=1 (force legacy HDA) plus `options snd-hda-intel dmic_detect=0`.
    boot.extraModprobeConfig = ''
      options snd-intel-dspcfg dsp_driver=3
    '';

    # SOF firmware is still required for the models that keep the mic on the DSP.
    hardware.firmware = [ pkgs.sof-firmware ];

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
