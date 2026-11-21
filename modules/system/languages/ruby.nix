{ pkgs, inputs, ... }:
let
  # The control-objects project pins Ruby 3.1.2. nixpkgs removed ruby_3_1
  # (EOL) and never carried 3.1.2, so this exact build comes from the
  # nixpkgs-ruby flake (see flake.nix). It is not added to PATH directly:
  # its `ruby`/`gem`/`bundle` would collide with ruby_4_0 below.
  ruby312 =
    inputs.nixpkgs-ruby.packages.${pkgs.stdenv.hostPlatform.system}."ruby-3.1.2";

  # Ruby 3.1.2's headers trip GCC 14+'s -Wincompatible-pointer-types error
  # (e.g. io-console, psych). The flag is downgraded to a warning so native
  # gem extensions still build.
  ruby312gcc = pkgs.writeShellScriptBin "gcc" ''
    exec ${pkgs.gcc}/bin/gcc -Wno-incompatible-pointer-types "$@"
  '';

  # Run commands with Ruby 3.1.2 first on PATH:
  #   ruby312 ruby -v
  #   ruby312 bundle install
  #   ruby312 gem install ruby-lsp
  #   ruby312 ruby-lsp
  # The package's gem home (~/.local/share/gem/ruby/3.1.0) is writable, so
  # gems installed there land in its bin dir. Put that bin dir first: a
  # `gem install bundler -v 2.3.27` must shadow the 2.3.7 bundled with Ruby
  # 3.1.2, which cannot parse `platforms: %i[windows jruby]` in the project's
  # Gemfile. libyaml is needed to build psych; the gcc wrapper handles the
  # pointer-type warnings.
  ruby312-wrapper = pkgs.writeShellScriptBin "ruby312" ''
    export PATH="$HOME/.local/share/gem/ruby/3.1.0/bin:${ruby312gcc}/bin:${ruby312}/bin:$PATH"
    # Do not append inherited values: Neovim's FHS wrapper exports
    # LD_LIBRARY_PATH=/usr/lib:/usr/lib64, which makes Ruby 3.1.2 load the
    # host glibc instead of its own RPATH and segfaults (signal 11).
    export C_INCLUDE_PATH="${pkgs.libyaml.dev}/include"
    export LIBRARY_PATH="${pkgs.libyaml}/lib"
    export LD_LIBRARY_PATH="${pkgs.libyaml}/lib"
    export PKG_CONFIG_PATH="${pkgs.libyaml.dev}/lib/pkgconfig"
    if [ "$#" -eq 0 ]; then
      exec ruby --version
    fi
    exec "$@"
  '';

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
    ruby_3_3

    # Exact Ruby 3.1.2 for control-objects; use `ruby312 <command>`.
    ruby312-wrapper

    # Rails 8 (bundled from RubyGems, see `rails` above)
    rails
    rubyPackages_4_0.rake

    rubyPackages_4_0.ruby-lsp
    rubyPackages_4_0.pry
    rubyPackages_4_0.debug
    rubyPackages_4_0.rspec
    rubyPackages_4_0.yard

    foreman
    patchelf
    pkg-config
    zlib
    openssl
    readline
    libffi
    gcc
  ];
}
