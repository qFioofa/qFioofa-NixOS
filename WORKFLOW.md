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
    │   │   ├── niri.nix
    │   │   ├── fonts.nix
    │   │   └── portals.nix
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
            ├── niri.nix
            ├── waybar.nix
            ├── rofi.nix
            └── mako.nix
```
