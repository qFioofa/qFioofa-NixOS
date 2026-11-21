{ pkgs, ... }:
{
  security.rtkit.enable = true;

  systemd.services.alsa-hdaudio-unmute = {
    description = "Unmute HDAudio speaker and microphone";
    wantedBy = [ "multi-user.target" ];
    wants = [ "sound.target" ];
    after = [ "sound.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.alsa-utils}/bin/amixer -c HDAudio sset Master unmute || true
      ${pkgs.alsa-utils}/bin/amixer -c HDAudio sset Speaker unmute || true
      ${pkgs.alsa-utils}/bin/amixer -c HDAudio sset Capture cap || true
      ${pkgs.alsa-utils}/bin/amixer -c HDAudio sset "Mic Boost" 2 || true
    '';
  };

  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
