{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme) bg bgSurface fg fgDim fgMuted primary radius radiusInner border;

  rofi = "${pkgs.rofi}/bin/rofi";
  nmcli = "${pkgs.networkmanager}/bin/nmcli";
  bluetoothctl = "${pkgs.bluez}/bin/bluetoothctl";
  awk = "${pkgs.gawk}/bin/awk";
  jq = "${pkgs.jq}/bin/jq";
  notify = "${pkgs.libnotify}/bin/notify-send";

  themeVars = { inherit bg bgSurface fg fgDim fgMuted primary radius radiusInner border; };

  # Shared theme: a small popup anchored to the top-right corner, just under
  # the bar, so it appears right next to the network/bluetooth icons.
  popupTheme = pkgs.replaceVars ./themes/popup.rasi themeVars;
  # Same look as popupTheme, but anchored top-left under the language module.
  layoutTheme = pkgs.replaceVars ./themes/layout-popup.rasi themeVars;

  layoutPopup = pkgs.writeShellScriptBin "layout-popup" (builtins.readFile (pkgs.replaceVars ./scripts/layout-popup.sh {
    inherit jq rofi;
    layoutTheme = "${layoutTheme}";
  }));

  wifiPopup = pkgs.writeShellScriptBin "wifi-popup" (builtins.readFile (pkgs.replaceVars ./scripts/wifi-popup.sh {
    inherit rofi nmcli awk notify;
    popupTheme = "${popupTheme}";
  }));

  btPopup = pkgs.writeShellScriptBin "bt-popup" (builtins.readFile (pkgs.replaceVars ./scripts/bt-popup.sh {
    inherit rofi bluetoothctl awk notify;
    popupTheme = "${popupTheme}";
  }));
in
{
  home.packages = [ wifiPopup btPopup layoutPopup ];
}
