{ pkgs, ... }: {
  programs.zsh = {
    enable                        = true;
    autosuggestion.enable         = true;
    syntaxHighlighting.enable     = true;
    historySubstringSearch.enable = true;
    history.ignoreDups            = true;

    shellAliases = {
      ls  = "eza --icons=always";
      ll  = "eza -la --icons=always --git";
      cat = "bat";
      vim = "nvim";
      lg  = "lazygit";
      nrs = "sudo nixos-rebuild switch --flake ~/.dotfiles#nixos";
      hms = "home-manager switch --flake ~/.dotfiles#qFioofa";
      ngc = "sudo nix-collect-garbage -d";
    };

    initExtra = ''
      eval "$(zoxide init zsh --cmd cd)"
      eval "$(starship init zsh)"
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      format      = "$directory$git_branch$git_status$nix_shell$line_break$character";
      character   = {
        success_symbol = "[❯](bold #a6e3a1)";
        error_symbol   = "[❯](bold #f38ba8)";
      };
      directory   = { style = "bold #89b4fa"; truncation_length = 4; };
      git_branch  = { symbol = " "; style = "bold #cba6f7"; };
      nix_shell   = { symbol = " "; style = "bold #89b4fa"; };
    };
  };
}
