
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    git-lfs
    act                # run github actions localy
    delta              # syntax-highlighting pager for git diff/blame
    difftastic         # structural, syntax-aware diff
    lazygit            # terminal UI for git

    coreutils          # ls, cat, cp, mv, head, tail, cut, sort, wc, ...
    gnused             # sed
    gawk               # awk
    gnugrep            # grep / egrep
    findutils          # find, xargs, locate
    diffutils          # diff, cmp, diff3
    less               # standard pager
    patch              # apply .patch / .diff files
    bc                 # arbitrary-precision calculator

    bat                # cat with syntax highlighting
    eza                # modern ls
    fd                 # modern find
    ripgrep            # modern grep
    ripgrep-all        # ripgrep across PDFs, docs, archives
    sd                 # intuitive sed replacement
    choose             # friendly cut / awk field selection
    procs              # modern ps
    duf                # friendly df
    dust               # modern du

    fzf                # fuzzy finder
    zoxide             # smarter cd
    tree               # directory tree view
    ncdu               # interactive disk usage explorer

    jq                 # JSON processor
    yq-go              # YAML/XML processor (jq counterpart)
    miller             # awk/sed/cut for CSV/TSV/JSON
    dos2unix           # line-ending conversion
    gettext            # i18n tooling (msgfmt, envsubst, ...)

    file               # identify file types
    xxd                # hex dump
    tealdeer           # tldr — concise example-driven man pages

    zip
    unzip
    p7zip
    gnutar             # tar
    gzip
    xz
    bzip2

    curl
    wget
    httpie             # human-friendly HTTP client

    iproute2           # ip, ss
    iputils            # ping, arping, tracepath
    traceroute
    netcat-gnu         # TCP/UDP swiss-army knife
    socat              # bidirectional data relay
    nmap               # network / port scanning
    whois              # domain / IP lookup
    dnsutils           # dig, nslookup, host
    gping              # ping with a live graph
    bandwhich          # bandwidth usage by process

    openssh            # ssh, scp, sftp, ssh-keygen
    rsync              # file sync / transfer

    btop               # resource monitor
    procps             # ps, top, free, uptime, vmstat, watch
    psmisc             # killall, pstree, fuser
    lsof               # list open files / sockets
    util-linux         # lsblk, mount, dmesg, hexdump, column, flock

    pciutils           # lspci
    usbutils           # lsusb
    dmidecode          # DMI / SMBIOS hardware table
    fastfetch          # system info display

    gcc                # C/C++ compiler
    dotnet-sdk         # C# compiler / .NET SDK
    kotlin             # Kotlin compiler
    nodejs             # JavaScript runtime / compiler
    typst              # markup-based typesetting compiler (tinymist LSP in nvim)
    gnumake            # make
    pkg-config         # build-time library metadata
    binutils           # objdump, nm, strings, ar, ld, readelf
    cppcheck           # C/C++ static analysis

    gdb                # GNU debugger
    strace             # trace system calls
    ltrace             # trace library calls
    valgrind           # memory error / leak detection
    hyperfine          # command-line benchmarking

    gnupg              # gpg
    openssl            # TLS, hashing, key generation

    pv                 # pipe viewer (progress bars)
    parallel           # GNU parallel
    moreutils          # sponge, ts, vidir, chronic, ifne
    entr               # run commands on file change
    expect             # automate interactive programs

    bash
    tmux               # terminal multiplexer
    bash-completion
    shellcheck         # shell script linter
    shfmt              # shell script formatter
    docker

    playerctl          # media player control
    cava               # audio visualizer

    xdg-utils

    asciiquarium
    cmatrix
    unimatrix
    sl
    aalib
    libcaca
    pipes
    cbonsai
    hollywood
    nyancat
    bb
    tty-clock
    moon-buggy
    ninvaders
  ];
}
