{ inputs, ... }:
{
  # Single source of truth: the FHS-wrapped Neovim 0.11.7 (with Mason support)
  # and config come straight from the qFioofa-Nvim flake — the exact same
  # package as `nix profile install github:qFioofa/qFioofa-Nvim`. Keeping the
  # definition here would let the two drift; importing the module guarantees
  # nvim is universally identical everywhere.
  imports = [ inputs.nvim-config.homeManagerModules.default ];
}
