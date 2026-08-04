{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme)
    bg bgSurface fg fgDim fgMuted
    primary success warning error
    violet tide amber coral;

  playerctl = "${pkgs.playerctl}/bin/playerctl";

  niriTaskbar = pkgs.rustPlatform.buildRustPackage rec {
    pname = "niri-taskbar";
    version = "0.3.0+niri.25.08";
    src = pkgs.fetchFromGitHub {
      owner = "LawnGnome";
      repo = "niri-taskbar";
      rev = "v0.3.0+niri.25.08";
      hash = "sha256-Gbzh4OTkvtP9F/bfDUyA14NH2DMDdr3i6oFoFwinEAg=";
    };
    cargoHash = "sha256-Ql9iqbbS3DY7o5/PR96c2t4VXKoS1kjZ9k3SfhNdbzE=";
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.gtk3 ];

    postPatch = ''
      substituteInPlace src/niri/state.rs \
        --replace-fail \
          'return Some(WindowWorkspace { window, workspace });' \
          'if workspace.is_active { return Some(WindowWorkspace { window, workspace }); }'

      substituteInPlace src/niri/state.rs \
        --replace-fail \
          '            _ => {}' \
          '            Event::WorkspaceActivated { id, focused } => {
                if let Some(Inner::Ready(state)) = &mut self.0 {
                    state.activate_workspace(id, focused);
                }
            }
            _ => {}'

      substituteInPlace src/niri/state.rs \
        --replace-fail \
          '    fn set_focus(&mut self, id: Option<u64>) {' \
          '    fn activate_workspace(&mut self, id: u64, focused: bool) {
        // A workspace becomes active on its own output, deactivating whichever
        // workspace was previously active there; focus is global across outputs.
        let output = self.workspaces.get(&id).and_then(|ws| ws.output.clone());
        for ws in self.workspaces.values_mut() {
            if ws.id == id {
                ws.is_active = true;
                if focused {
                    ws.is_focused = true;
                }
            } else {
                if ws.output == output {
                    ws.is_active = false;
                }
                if focused {
                    ws.is_focused = false;
                }
            }
        }
    }

    fn set_focus(&mut self, id: Option<u64>) {'
    '';
  };
  niriTaskbarLib = "${niriTaskbar}/lib/libniri_taskbar.so";

  nowPlaying = pkgs.writeShellScript "waybar-nowplaying" (builtins.readFile (pkgs.replaceVars ./scripts/waybar-nowplaying.sh {
    inherit playerctl;
    sed = "${pkgs.gnused}/bin/sed";
    cut = "${pkgs.coreutils}/bin/cut";
  }));
in
{
  programs.waybar = {
    enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 36;
      spacing = 0;
      margin-top = 6;
      margin-left = 8;
      margin-right = 8;

      modules-left = [ "group/left-a" "group/left-b" "group/left-c" ];
      modules-center = [ "group/center-a" "group/center-b" ];
      modules-right = [ "group/right-a" "group/right-b" ];

      "group/left-a" = {
        orientation = "horizontal";
        modules = [ "clock" "niri/language" ];
      };
      "group/left-b" = {
        orientation = "horizontal";
        modules = [ "niri/workspaces" ];
      };
      # Media capsule: now-playing block + sound controls live together.
      "group/left-c" = {
        orientation = "horizontal";
        modules = [ "custom/player" "group/audio" ];
      };
      # Volume icon in the bar; the slider slides out on hover.
      "group/audio" = {
        orientation = "horizontal";
        drawer = {
          transition-duration = 300;
          transition-left-to-right = true;
          children-class = "drawer-child";
        };
        modules = [ "pulseaudio" "pulseaudio/slider" ];
      };

      "group/center-a" = {
        orientation = "horizontal";
        modules = [ "tray" ];
      };
      # Taskbar of open windows, sitting to the right of the tray. niri-taskbar
      # renders real app icons (per output, ordered by workspace then open time).
      "group/center-b" = {
        orientation = "horizontal";
        modules = [ "cffi/niri-taskbar" ];
      };

      # Hardware controls: brightness drawer + idle inhibitor.
      "group/right-a" = {
        orientation = "horizontal";
        modules = [ "group/brightness" "idle_inhibitor" ];
      };
      # Brightness icon in the bar; the slider slides out on hover.
      "group/brightness" = {
        orientation = "horizontal";
        drawer = {
          transition-duration = 300;
          transition-left-to-right = true;
          children-class = "drawer-child";
        };
        modules = [ "backlight" "backlight/slider" ];
      };
      # Status + system capsule.
      "group/right-b" = {
        orientation = "horizontal";
        modules = [ "network" "bluetooth" "battery" "custom/swaync" "custom/settings" "custom/power" ];
      };

      clock = {
        format = "󰥔  {:%H:%M}";
        tooltip-format = "<tt>{calendar}</tt>";
        # Left-click opens the rofi calendar + date-tools app (the notification
        # center stays on the bell icon). No format-alt here on purpose: Waybar's
        # left-click toggles format-alt *and* runs on-click, so a date format
        # would flip the clock to the date on every click — we only want rofi.
        # The tooltip calendar stays as a quick at-a-glance peek on hover.
        on-click = "calendar";
        calendar = {
          mode = "month";
          # In year mode, lay the 12 months out 3 per row.
          mode-mon-col = 3;
          weeks-pos = "left";
          # Number of months to step per scroll tick (paired with the
          # shift_up/shift_down actions below).
          on-scroll = 1;
          format = {
            today = "<span color='${primary}'><b>{}</b></span>";
          };
        };
        # Hover the clock to see the calendar, then:
        #   scroll up/down  → page through previous / next months
        #   right-click     → toggle between month and full-year view
        #   middle-click    → jump back to the current month
        actions = {
          on-click-right = "mode";
          on-click-middle = "shift_reset";
          on-scroll-up = "shift_up";
          on-scroll-down = "shift_down";
        };
      };

      "custom/swaync" = {
        tooltip = true;
        format = "{icon}";
        format-icons = {
          notification = "<span foreground='${error}'>󰂞</span>";
          none = "󰂚";
          dnd-notification = "<span foreground='${error}'>󰂠</span>";
          dnd-none = "󰂛";
          inhibited-notification = "<span foreground='${error}'>󰂞</span>";
          inhibited-none = "󰂚";
          dnd-inhibited-notification = "<span foreground='${error}'>󰂠</span>";
          dnd-inhibited-none = "󰂛";
        };
        return-type = "json";
        exec-if = "which swaync-client";
        exec = "swaync-client -swb";
        on-click = "swaync-client -t -sw";
        on-click-right = "swaync-client -d -sw";
        escape = true;
      };

      # Settings gear — opens GNOME Settings (the wrapped gnome-control-center
      # from home/programs/apps.nix; resolved by name via the session PATH).
      "custom/settings" = {
        tooltip = false;
        format = "󰒓";
        on-click = "gnome-control-center";
      };

      "custom/power" = {
        tooltip = false;
        format = "󰐥";
        on-click = "powermenu";
      };

      # Now-playing block — click toggles play/pause, scroll changes track.
      "custom/player" = {
        return-type = "json";
        exec = "${nowPlaying}";
        interval = 2;
        format = "{}";
        escape = true;
        on-click = "${playerctl} play-pause";
        on-click-right = "${playerctl} next";
        on-scroll-up = "${playerctl} next";
        on-scroll-down = "${playerctl} previous";
      };

      # Native niri taskbar (CFFI module) — real app icons, click to focus.
      "cffi/niri-taskbar" = {
        module_path = niriTaskbarLib;
      };

      "niri/language" = {
        format = "󰌌  {short}";
        tooltip-format = "{long}";
        on-click = "layout-popup";
      };

      "niri/workspaces" = {
        format = "{index}";
        on-click = "activate";
      };

      tray = {
        spacing = 8;
        icon-size = 18;
      };

      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = "󰅶";
          deactivated = "󰾪";
        };
        tooltip-format-activated = "Idle inhibitor: on";
        tooltip-format-deactivated = "Idle inhibitor: off";
      };

      network = {
        format-wifi = "󰤨  {essid} ({signalStrength}%)";
        format-ethernet = "󰈀  {ifname}";
        format-disconnected = "󰤭  off";
        tooltip-format-wifi = "{ipaddr}/{cidr}\n{signaldBm}dBm @ {frequency}GHz";
        tooltip-format-ethernet = "{ipaddr}/{cidr}";
        max-length = 24;
        on-click = "wifi-popup";
        on-click-right = "nm-connection-editor";
      };

      bluetooth = {
        format = "󰂯";
        format-disabled = "󰂲";
        format-off = "󰂲";
        format-connected = "󰂱  {num_connections}";
        tooltip-format = "{controller_alias}\t{controller_address}";
        tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
        on-click = "bt-popup";
        on-click-right = "blueman-manager";
      };

      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{icon}  {capacity}%";
        format-charging = "󰂄  {capacity}%";
        format-plugged = "󰂄  {capacity}%";
        format-full = "󰁹  Full";
        format-icons = [ "󰁻" "󰁽" "󰁿" "󰂁" "󰁹" ];
        tooltip-format = "{timeTo} ({power:.1f}W)";
      };

      pulseaudio = {
        format = "{icon}  {volume}%";
        format-muted = "󰝟  muted";
        format-icons = {
          default = [ "󰕿" "󰖀" "󰕾" ];
        };
        on-scroll-up = "swayosd-client --output-volume raise";
        on-scroll-down = "swayosd-client --output-volume lower";
        on-click = "swayosd-client --output-volume mute-toggle";
        on-click-right = "pavucontrol";
      };

      "pulseaudio/slider" = {
        min = 0;
        max = 100;
        orientation = "horizontal";
      };

      backlight = {
        format = "󰃠  {percent}%";
        tooltip-format = "Brightness: {percent}%";
        on-scroll-up = "swayosd-client --brightness raise";
        on-scroll-down = "swayosd-client --brightness lower";
      };

      "backlight/slider" = {
        min = 0;
        max = 100;
        orientation = "horizontal";
      };
    };

    style = builtins.readFile (pkgs.replaceVars ./themes/waybar.css {
      inherit bg bgSurface fg fgDim fgMuted primary success warning error violet tide amber coral;
    });
  };
}
