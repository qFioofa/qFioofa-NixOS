# qFioofa NixOS — Workflow

## Project structure

```
qFioofa-NixOS/
├── flake.nix                    # Entry point — inputs & host declarations
├── scripts/
│   └── deploy.sh                # Helper script wrapping nixos-rebuild
├── hosts/
│   ├── default.nix          # Host-level imports (all modules)
│   └── hardware.nix         # Hardware config (replace with nixos-generate-config output)
│
├── modules/
│   ├── system/                  # OS-level settings — run as root
│   │   ├── boot.nix             #   Bootloader & kernel params
│   │   ├── locale.nix           #   Timezone, locale, keyboard layout
│   │   ├── networking.nix       #   NetworkManager & firewall
│   │   ├── audio.nix            #   PipeWire audio stack
│   │   ├── bluetooth.nix        #   Bluetooth + Blueman
│   │   └── users.nix            #   User account, shell, nix settings
│   │
│   ├── desktop/                 # Graphical environment — system level
│   │   ├── fonts.nix            #   Nerd fonts + system font defaults
│   │   └── portals.nix          #   XDG portals (file picker, screen share)
│   │
│   └── apps/                    # System-wide package installation
│       ├── default.nix          #   Imports all app modules
│       ├── global.nix           #   Core CLI tools (bat, eza, fzf, ripgrep…)
│       ├── nvim.nix             #   LSP servers + build tools for neovim
│       ├── tmux.nix             #   tmux + tmuxinator
│       ├── zsh.nix              #   Enable zsh system-wide + starship
│       ├── git.nix              #   git, gh CLI, lazygit, git-delta
│       └── terminal.nix         #   kitty, wl-clipboard, screenshot tools
│
└── home/                        # home-manager — user dotfiles
    ├── default.nix              #   Root: username, stateVersion, imports
    ├── apps/
    │   ├── nvim.nix
    │   ├── tmux.nix
    │   ├── zsh.nix
    │   ├── git.nix
    └── desktop/
        ├── waybar/default.nix   #   Bar modules, layout, CSS
        ├── rofi/default.nix     #   Launcher config + Catppuccin theme
        └── mako/default.nix     #   Notification daemon appearance
```
