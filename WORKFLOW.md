# qFioofa NixOS — Workflow

## Project structure

```
qFioofa-NixOS/
├── flake.nix
├── scripts/
│   └── deploy.sh
└── src/
    ├── hosts/
    │   ├── default.nix
    │   └── hardware.nix
    ├── modules/
    │   ├── system/
    │   │   ├── boot.nix
    │   │   ├── locale.nix
    │   │   ├── networking.nix
    │   │   ├── audio.nix
    │   │   ├── bluetooth.nix
    │   │   └── users.nix
    │   ├── desktop/
    │   │   ├── niri.nix      # programs.niri + swaylock PAM + keyring
    │   │   ├── xwayland.nix  # xwayland-satellite for X11 apps
    │   │   ├── fonts.nix
    │   │   ├── portals.nix
    │   │   └── keyd.nix      # tap Win → F13 → launcher (overload)
    │   └── apps/
    │       ├── default.nix
    │       ├── global.nix
    │       ├── nvim.nix
    │       ├── tmux.nix
    │       ├── zsh.nix
    │       ├── git.nix
    │       └── terminal.nix
    └── home/
        ├── default.nix
        ├── apps/
        │   ├── nvim.nix
        │   ├── terminals/       # default.nix, palette.nix, ghostty/alacritty/foot/wezterm
        │   ├── tmux.nix
        │   ├── zsh.nix
        │   └── git.nix
        └── desktop/
            ├── niri.nix       # compositor config (config.kdl) + wallpaper
            ├── waybar.nix     # top bar (niri workspaces/language modules)
            ├── fuzzel.nix     # native-wayland app launcher (Mod+D / Win)
            ├── mako.nix       # notification daemon
            ├── idle.nix       # swayidle + swaylock (auto/manual lock)
            ├── clipboard.nix  # wl-clipboard + cliphist history (Mod+V)
            ├── screenshot.nix # grim/slurp/satty annotated capture
            ├── media.nix      # playerctl for media keys
            ├── polkit.nix     # polkit-gnome authentication agent
            └── theme.nix      # cursor + GTK/Qt dark theming
```

All desktop colors follow the **yugen-ash** palette (`#151515` bg / `#FFBE89`
accent), kept in sync across niri, waybar, fuzzel, mako, swaylock and the
terminals (`src/home/apps/terminals/palette.nix`).

## Login flow

SDDM (Wayland) auto-logs `qFioofa` straight into the **niri** session
(`src/hosts/default.nix`). niri starts `graphical-session.target`, which brings
up the home-manager user services — waybar, mako, swayidle, cliphist and the
polkit agent — automatically. swaylock can unlock because the system declares
`security.pam.services.swaylock` (`src/modules/desktop/niri.nix`).

## App launcher

`keyd` (`src/modules/desktop/keyd.nix`) overloads the left Win/Super key: held
it stays Super (so every `Mod+…` bind works), tapped alone it emits **F13**.
niri binds both `Mod+D` and `F13` to **fuzzel**, a native-Wayland launcher that
renders centered on screen by default (`src/home/desktop/fuzzel.nix`) — so a
quick tap of Win opens the minimalist app picker in the middle of the screen.
`Mod+V` reuses fuzzel in `--dmenu` mode for the clipboard-history picker.
