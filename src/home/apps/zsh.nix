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

    # `initExtra` was replaced by `initContent` in current home-manager.
    initContent = ''
      eval "$(zoxide init zsh --cmd cd)"
      eval "$(starship init zsh)"
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      format      = "$directory$git_branch$git_status$nix_shell$line_break$character";
      # yugen-ash palette — matches the desktop rice.
      character   = {
        success_symbol = "[❯](bold #7EAB8E)";
        error_symbol   = "[❯](bold #F57A7A)";
      };
      directory   = { style = "bold #79A0AA"; truncation_length = 4; };
      git_branch  = { symbol = " "; style = "bold #FFBE89"; };
      nix_shell   = { symbol = " "; style = "bold #79A0AA"; };
    };
  };
}
