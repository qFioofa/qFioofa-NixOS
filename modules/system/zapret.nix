{ ... }:
{
  # nixpkgs ships its own services.zapret module, which collides with the aca
  # flake's module (added in flake.nix). Disable the built-in one so the flake's
  # raw-config interface is the one in effect.
  disabledModules = [ "services/networking/zapret.nix" ];

  # DPI-bypass daemon. The zapret nixosModule (added in flake.nix) takes a raw
  # zapret config string and runs the nfqws daemon, applying its own nftables
  # rules (INIT_APPLY_FW=1).
  #
  # NOTE: NFQWS_OPT_DESYNC below is a sensible general-purpose baseline. The
  # desync method that actually defeats your ISP's DPI varies per provider — run
  # zapret's `blockcheck` tool and copy the winning options here if a site is
  # still blocked.
  services.zapret = {
    enable = true;
    config = ''
      FWTYPE=nftables
      MODE=nfqws
      MODE_HTTP=1
      MODE_HTTPS=1
      MODE_QUIC=1
      DESYNC_MARK=0x40000000
      NFQWS_OPT_DESYNC="--dpi-desync=fake,disorder2 --dpi-desync-ttl=0 --dpi-desync-fooling=md5sig"
      FLOWOFFLOAD=donttouch
      INIT_APPLY_FW=1
      DISABLE_IPV6=1
    '';
  };
}
