{ lib
, stdenvNoCC
, fetchFromGitHub
, makeWrapper
, bash
, python3
, rofi
, wl-clipboard
, coreutils
, gnused
, gnugrep
, procps
, themeRasi
, themeCfg
, customActions
, dayMenu
}:

stdenvNoCC.mkDerivation {
  pname = "naivecalendar";
  version = "2.0.1";

  src = fetchFromGitHub {
    owner = "Daguhh";
    repo = "naivecalendar";
    rev = "3ea9588cb8c513135b5379917d7af3bbed5a7115";
    hash = "sha256-m0KoCY6DmRBaia6YjBZZ/x5NSTc5kGvoyH7+ohxXz4g=";
  };

  patches = [ ./naivecalendar.patch ];

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/naivecalendar/themes
    mkdir -p $out/share/naivecalendar/global

    install -Dm755 src/naivecalendar.py $out/share/naivecalendar/naivecalendar.py
    install -Dm755 src/naivecalendar.sh $out/share/naivecalendar/naivecalendar.sh
    install -Dm644 ${themeRasi} $out/share/naivecalendar/themes/nixos.rasi
    install -Dm644 ${themeCfg} $out/share/naivecalendar/themes/nixos.cfg
    install -Dm644 ${customActions} $out/share/naivecalendar/global/custom_actions.cfg
    install -Dm644 ${./events.cfg} $out/share/naivecalendar/global/events.cfg
    install -Dm644 LICENSE $out/share/naivecalendar/LICENSE

    makeWrapper ${bash}/bin/bash $out/bin/naivecalendar \
      --add-flags "$out/share/naivecalendar/naivecalendar.sh" \
      --add-flags "-t nixos" \
      --set NAIVECALENDAR_DAY_COMMAND "${dayMenu}" \
      --prefix PATH : ${lib.makeBinPath [
        rofi
        python3
        wl-clipboard
        coreutils
        gnused
        gnugrep
        procps
        bash
      ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Rofi calendar popup, vendored for the NixOS desktop";
    license = licenses.mit0;
    maintainers = [ ];
  };
}
