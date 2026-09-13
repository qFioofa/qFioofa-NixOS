{ pkgs, config, ... }:
let
  zapret = config.services.zapret.package;
  fake = "${zapret}/usr/share/zapret/files/fake";

  fakeTls = "${fake}/tls_clienthello_www_google_com.bin";
  fakeQuic = "${fake}/quic_initial_www_google_com.bin";
  fakeStun = "${fake}/stun.bin";

  hostlist = pkgs.writeText "zapret-hostlist" (pkgs.lib.fileContents ./data/zapret-hostlist.txt);
in
{
  # DPI-bypass service based on Flowseal/zapret-discord-youtube strategies,
  # adapted for Linux via nixpkgs' built-in zapret module (nfqws + iptables NFQUEUE).
  #
  # Strategy profiles (separated by --new):
  #   0: QUIC (UDP 443)     — fake desync, repeats=6, google.com QUIC Initial decoy
  #   1: Discord voice/STUN (UDP 19294-19344, 50000-50100) — fake desync, repeats=6
  #   2: TLS (TCP 443)      — fake desync + ts fooling, repeats=6, google.com ClientHello
  #   3: Alt HTTPS (TCP 2053,2083,2087,2096,8443) — multisplit seqovl=681 pos=1
  #   4: TCP 80,443 general  — multisplit seqovl=568 pos=1, 4pda_to pattern
  #   5: UDP 443 ipset fallback — fake, repeats=6
  #   6: TCP 80,443,8443 ipset fallback — multisplit seqovl=568 pos=1
  #   7: Game TCP fallback — multisplit, any-protocol, cutoff=n3
  #   8: Game UDP fallback — fake, repeats=12, any-protocol, cutoff=n2
  #
  # Domains: Discord ecosystem, YouTube/Google, Cloudflare DoH/ECH/CDN
  # (see modules/system/data/zapret-hostlist.txt)
  #
  # The desync method is ISP-specific. If a site stays blocked, run
  # `nix-shell -p nftables zapret --command blockcheck` and adapt the params.
  services.zapret = {
    enable = true;

    udpSupport = true;
    udpPorts = [
      "443"
      "19294:19344"
      "50000:50100"
    ];
    httpSupport = false;

    params = [
      # Profile 0 — QUIC (UDP 443)
      "--filter-udp=443"
      "--hostlist=${hostlist}"
      "--dpi-desync=fake"
      "--dpi-desync-repeats=6"
      "--dpi-desync-fake-quic=@${fakeQuic}"
      "--new"

      # Profile 1 — Discord voice / STUN (UDP 19294-19344, 50000-50100)
      # NB: nfqws uses '-' for port ranges, unlike the iptables ':' in udpPorts
      "--filter-udp=19294-19344,50000-50100"
      "--dpi-desync=fake"
      "--dpi-desync-fake-unknown-udp=@${fakeStun}"
      "--dpi-desync-repeats=6"
      "--new"

      # Profile 2 — TLS (TCP 443)
      "--filter-tcp=443"
      "--hostlist=${hostlist}"
      "--dpi-desync=fake"
      "--dpi-desync-repeats=6"
      "--dpi-desync-fooling=ts"
      "--dpi-desync-fake-tls=@${fakeTls}"
      "--new"

      # Profile 3 — Alt HTTPS ports (discord.media and others)
      "--filter-tcp=2053,2083,2087,2096,8443"
      "--hostlist=${hostlist}"
      "--dpi-desync=multisplit"
      "--dpi-desync-split-seqovl=681"
      "--dpi-desync-split-pos=1"
      "--dpi-desync-split-seqovl-pattern=@${fakeTls}"
      "--new"

      # Profile 4 — General TCP (80,443) for hostlisted domains
      "--filter-tcp=80,443"
      "--hostlist=${hostlist}"
      "--dpi-desync=multisplit"
      "--dpi-desync-split-seqovl=568"
      "--dpi-desync-split-pos=1"
      "--dpi-desync-split-seqovl-pattern=@${fakeTls}"
      "--new"

      # Profile 5 — QUIC ipset fallback (UDP 443, no hostlist)
      "--filter-udp=443"
      "--dpi-desync=fake"
      "--dpi-desync-repeats=6"
      "--dpi-desync-fake-quic=@${fakeQuic}"
      "--new"

      # Profile 6 — TCP ipset fallback (80,443,8443, no hostlist)
      "--filter-tcp=80,443,8443"
      "--dpi-desync=multisplit"
      "--dpi-desync-split-seqovl=568"
      "--dpi-desync-split-pos=1"
      "--dpi-desync-split-seqovl-pattern=@${fakeTls}"
      "--new"

      # Profile 7 — Game TCP fallback (any TCP above 1023) — range syntax uses '-'
      "--filter-tcp=1024-65535"
      "--dpi-desync=multisplit"
      "--dpi-desync-any-protocol=1"
      "--dpi-desync-cutoff=n3"
      "--dpi-desync-split-seqovl=568"
      "--dpi-desync-split-pos=1"
      "--dpi-desync-split-seqovl-pattern=@${fakeTls}"
      "--new"

      # Profile 8 — Game UDP fallback (any UDP above 1023) — range syntax uses '-'
      "--filter-udp=1024-65535"
      "--dpi-desync=fake"
      "--dpi-desync-repeats=12"
      "--dpi-desync-any-protocol=1"
      "--dpi-desync-fake-unknown-udp=@${fakeStun}"
      "--dpi-desync-cutoff=n2"
    ];
  };

  # Race fix: nfqws must start after iptables NFQUEUE rules exist.
  # Without this, nfqws can bind the queue before the rules are applied,
  # and DPI bypass silently does nothing. See bol-van/zapret#333.
  systemd.services.zapret = {
    after = [ "network-online.target" "firewall.service" ];
    wants = [ "network-online.target" ];
    partOf = [ "firewall.service" ];
  };
}
