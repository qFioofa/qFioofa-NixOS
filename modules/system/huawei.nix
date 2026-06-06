{ config, lib, pkgs, ... }:
let
  cfg = config.hardware.huawei.matebook;
in
{
  # Hardware quirk fixes for Huawei Matebook laptops. Everything here is gated
  # behind `hardware.huawei.matebook.enable`, which is only switched on by the
  # Huawei host (hosts/qFioofa) — so on any non-Huawei machine the whole module
  # evaluates to nothing and none of these kernel/firmware tweaks are applied.
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
    # --- Audio: "Dummy Output" + dead internal microphone ---------------------
    # Huawei Matebooks ship a broken SOF/DSP ACPI description: the firmware
    # advertises a DSP audio path that doesn't actually drive the Realtek codec,
    # so PipeWire/ALSA enumerate only a "Dummy Output" and the internal mic never
    # shows up. Forcing the legacy HDA driver (dsp_driver=1) instead of SOF, and
    # disabling digital-mic autodetect (dmic_detect=0), restores both speakers
    # and the internal microphone.
    #
    # NOTE: a minority of Matebook models are the inverse — they *need* SOF. If
    # audio is still dead after this, try dsp_driver=3 (force SOF) here instead.
    boot.extraModprobeConfig = ''
      options snd-intel-dspcfg dsp_driver=1
      options snd-hda-intel dmic_detect=0
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
