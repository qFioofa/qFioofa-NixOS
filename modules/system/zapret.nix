{ pkgs, config, ... }:
let
  # The package actually used by the service, so the fake-payload paths below
  # always point at the same store path nfqws runs from.
  zapret = config.services.zapret.package;
  fake = "${zapret}/usr/share/zapret/files/fake";

  # Pre-shipped, network-captured decoy packets. nfqws sends these as the
  # "fake" desync payload so the DPI sees a legitimate-looking google.com
  # handshake and lets the real (split/reordered) one through.
  fakeTls = "${fake}/tls_clienthello_www_google_com.bin";
  fakeQuic = "${fake}/quic_initial_www_google_com.bin";

  # Domains to desync. Scoped per-profile via --hostlist so nothing else on the
  # machine is touched. nfqws auto-matches subdomains, so the apex is enough.
  hostlist = pkgs.writeText "zapret-hostlist" (builtins.concatStringsSep "\n" [
    # YouTube / Google video
    "youtube.com"
    "youtu.be"
    "googlevideo.com"
    "ytimg.com"
    "ggpht.com"
    "youtubei.googleapis.com"
    "jnn-pa.googleapis.com"
    "googleapis.com"
    "gstatic.com"
    "gvt1.com"
    "google.com"
    # Discord
    "discord.com"
    "discord.gg"
    "discord.media"
    "discordapp.com"
    "discordapp.net"
  ]);
in
{
  # DPI-bypass daemon, using nixpkgs' built-in module. Its iptables rules use
  # --queue-bypass, so traffic flows normally if nfqws ever fails instead of the
  # whole connection being blackholed (the failure mode of the old flake module).
  #
  # The previous config only desynced TCP 443 and YouTube still didn't load,
  # because modern YouTube/Chrome speaks QUIC (HTTP/3 over UDP 443) — which the
  # ISP throttles and the TCP-only bypass never saw. We now route UDP 443 too and
  # run two nfqws strategy profiles (split with --new), following the approach in
  # https://github.com/Sergeydigl3/zapret-discord-youtube-linux:
  #   * QUIC (UDP 443): fake desync with a real google.com QUIC Initial decoy.
  #   * TLS  (TCP 443): fake desync, ts fooling, real google.com ClientHello decoy.
  # Each profile is scoped to ${hostlist} so only YouTube/Discord are affected.
  #
  # The desync method is ISP-specific. If a site stays blocked, run
  # `nix-shell -p nftables zapret --command blockcheck` and adapt the params here.
  services.zapret = {
    enable = true;

    # QUIC needs UDP 443 routed into the NFQUEUE; without this nfqws never sees it.
    udpSupport = true;
    udpPorts = [ "443" ];
    # Port 80 is plain HTTP; YouTube/Discord are HTTPS-only, so skip it and keep
    # the TLS profile's filter clean.
    httpSupport = false;

    # whitelist/blacklist are left empty on purpose: scoping is done per-profile
    # with the inline --hostlist below, because the module appends its own
    # --hostlist at the very end where it would only bind to the last profile.
    params = [
      # Profile 0 — QUIC (UDP 443)
      "--filter-udp=443"
      "--hostlist=${hostlist}"
      "--dpi-desync=fake"
      "--dpi-desync-repeats=6"
      "--dpi-desync-fake-quic=@${fakeQuic}"
      "--new"
      # Profile 1 — TLS (TCP 443)
      "--filter-tcp=443"
      "--hostlist=${hostlist}"
      "--dpi-desync=fake"
      "--dpi-desync-repeats=6"
      "--dpi-desync-fooling=ts"
      "--dpi-desync-fake-tls=@${fakeTls}"
    ];
  };

  # The upstream nixpkgs zapret unit only orders `After=network.target`, with no
  # relationship to firewall.service — yet firewall.service is what installs the
  # `mangle POSTROUTING ... -j NFQUEUE --queue-num 200` redirect rules that feed
  # nfqws. At boot the two race, so nfqws can bind the queue before (or instead
  # of) the rules existing, and DPI bypass silently does nothing until something
  # is restarted by hand. Wait for the firewall (and a real network) first, and
  # tie nfqws's lifecycle to the firewall so it always rebinds after the rules
  # are (re)applied. See https://github.com/bol-van/zapret/issues/333 and the
  # NixOS firewall-ordering discussions.
  systemd.services.zapret = {
    after = [ "network-online.target" "firewall.service" ];
    wants = [ "network-online.target" ];
    partOf = [ "firewall.service" ];
  };
}
