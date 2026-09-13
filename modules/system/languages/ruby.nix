{ pkgs, ... }:
let
  # Rails 8 is not yet packaged in the pinned nixpkgs gemset (it ships 7.2.3),
  # so it is built from the RubyGems sources via a bundlerApp (Gemfile +
  # Gemfile.lock + gemset.nix generated with `bundle lock` and `bundix`).
  rails = pkgs.bundlerApp {
    pname = "rails";
    # Ruby 4.0 matches the interpreter used below; the gemset is generated
    # against the same gemset.nix file this flake pins.
    ruby = pkgs.ruby_4_0;
    gemdir = ./ruby/rails;
    exes = [ "rails" ];
  };
in {
  # Ruby 4.0 is the newest line available in the pinned nixpkgs snapshot
  # (ruby_3_3 / ruby_3_4 / ruby_4_0 — there is no newer one without bumping
  # the nixpkgs input, which the flake deliberately pins for niri). Only gems
  # that actually run on ruby 4.0 are listed: solargraph and rubocop were
  # removed because they crash on this interpreter in this snapshot
  # (solargraph demands bundler ~> 2.0 while ruby 4.0 ships bundler 4.0;
  # rubocop dies in the rubygems 3.7.2 resolver). ruby-lsp covers the LSP
  # role. Keep this list conflict-free: every tool here must satisfy its
  # dependencies from this one combined gem environment.
  environment.systemPackages = with pkgs; [
    ruby_4_0

    # Rails 8 (bundled from RubyGems, see `rails` above)
    rails
    rubyPackages_4_0.rake

    rubyPackages_4_0.ruby-lsp
    rubyPackages_4_0.pry
    rubyPackages_4_0.debug
    rubyPackages_4_0.rspec
    rubyPackages_4_0.yard

    patchelf
    pkg-config
    zlib
    openssl
    readline
    libffi
    gcc
  ];
}