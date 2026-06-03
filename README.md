# qFioofa-NixOS

A simple, stable NixOS configuration built around the **niri** Wayland compositor.

- Flake-based, `nixpkgs` unstable.
- niri configured with typed settings via [sodiboo/niri-flake](https://github.com/sodiboo/niri-flake).
- [home-manager](https://github.com/nix-community/home-manager) as a NixOS module — one rebuild deploys system **and** user config.
- Login: `greetd` + `tuigreet`. Desktop: niri + foot + fuzzel + waybar + mako.

## Layout

```
flake.nix                  inputs + nixosConfigurations."nixos"
hosts/default/
  default.nix              the host: imports everything, hostName, stateVersion, HM wiring
  hardware.nix             machine-specific (REPLACE before deploying — see below)
modules/system/            OS-level: boot, locale, networking, audio, users
modules/desktop/           niri enable + portals, greetd login, fonts
home/                      user dotfiles: niri settings, waybar, foot, fuzzel, mako
scripts/deploy.sh          convenience wrapper around nixos-rebuild
```

System-wide / needs root → `modules/`. Per-user dotfiles → `home/`.

## First-time setup

1. **Generate real hardware config** on the target machine and overwrite the placeholder:
   ```sh
   nixos-generate-config --show-hardware-config | sudo tee hosts/default/hardware.nix
   ```
2. Adjust `modules/system/locale.nix` (timezone/locale) and the username if it isn't `qFioofa`.
3. Build and switch:
   ```sh
   sudo nixos-rebuild switch --flake .#nixos
   # or: ./scripts/deploy.sh switch
   ```
4. Reboot, log in via tuigreet (initial password `nixos` — change it with `passwd`).

## Default keybinds (Mod = Super)

| Key | Action |
|-----|--------|
| `Mod+Return` | terminal (foot) |
| `Mod+D` | launcher (fuzzel) |
| `Mod+Q` | close window |
| `Mod+Left/Right` | focus column |
| `Mod+Shift+Left/Right` | move column |
| `Mod+1..4` | switch workspace |
| `Mod+F` / `Mod+Shift+F` | maximize / fullscreen |
| `Print` | screenshot |
| `Mod+Shift+E` | quit niri |

See `home/niri.nix` for the full list and to customize.
