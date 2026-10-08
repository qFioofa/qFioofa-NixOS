# qFioofa-NixOS

A simple, stable NixOS configuration built around the **niri** Wayland compositor.

- Flake-based, `nixpkgs` unstable.
- niri configured with typed settings via [sodiboo/niri-flake](https://github.com/sodiboo/niri-flake).
- [home-manager](https://github.com/nix-community/home-manager) as a NixOS module — one rebuild deploys system **and** user config.
- Login: `greetd` + `tuigreet`. Desktop: niri + foot + fuzzel + waybar + mako.

## Layout

```
flake.nix                  inputs + nixosConfigurations.{nixos,qFioofa,wsl}
hosts/<name>/
  default.nix              the host: imports everything, hostName, stateVersion, HM wiring
  hardware.nix             machine-specific (REPLACE before deploying — see below)
modules/system/            OS-level: boot, locale, networking, audio, users
modules/desktop/           niri enable + portals, greetd login, fonts
modules/wsl/               headless OS subset for the WSL2 host
home/                      user dotfiles: niri settings, waybar, foot, fuzzel, mako
home/wsl.nix               headless user profile (terminal/dev only)
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

## WSL (headless) profile

`nixosConfigurations.wsl` runs the same flake as a WSL2 distro on Windows. It is
deliberately headless: no niri, greetd, waybar or GUI apps — only the OS subset
that makes sense under WSL and a terminal/dev home profile.

- System: `modules/wsl/` imports locale, `nix-ld`, `envfs`, zsh/user tooling, the
  language toolchains and Docker; it drops boot/plymouth/audio/bluetooth/
  fingerprint/virtualbox/amnezia/zapret/cisco-vpn and all of `modules/desktop/`.
  Networking uses WSL's own stack (NetworkManager is **not** enabled).
- User: `home/wsl.nix` pulls the terminal feature set (`configSpec/terminal.nix`:
  zsh, nvim, tmux, lazygit, clangd), the CLI toolbox and the AI/data-science
  packages. GUI modules (`configSpec/gui.nix`), `home/desktop/` and `apps.nix`
  are excluded.
- User `qFioofa` has passwordless `sudo` (same password hash as the desktop hosts).

Install NixOS-WSL on Windows, then from inside the distro:

```sh
git clone <this repo> ~/nixos && cd ~/nixos
sudo nixos-rebuild switch --flake .#wsl
# or: ./scripts/deploy.sh wsl
```

See `home/niri.nix` for the full list and to customize.
