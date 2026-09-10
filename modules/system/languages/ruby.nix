{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ruby_4_0

    rubyPackages_4_0.rails
    rubyPackages_4_0.rake

    rubyPackages_4_0.ruby-lsp
    rubyPackages_4_0.rubocop
    rubyPackages_4_0.pry
    rubyPackages_4_0.debug
    rubyPackages_4_0.solargraph
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