{ ... }: {
  programs.git = {
    enable    = true;
    userName  = "qFioofa";
    userEmail = "penavana1@gmail.com";

    delta.enable = true;

    extraConfig = {
      init.defaultBranch   = "main";
      push.autoSetupRemote = true;
      pull.rebase          = false;
    };

    aliases = {
      lg   = "log --oneline --graph --decorate --all";
      undo = "reset HEAD~1 --mixed";
    };

    ignores = [ ".DS_Store" "*.swp" ".direnv" "result" ];
  };
}
