{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ruby_3_3

    rubyPackages_3_3.bundler
    rubyPackages_3_3.rails
    rubyPackages_3_3.rake

    rubyPackages_3_3.ruby-lsp
    rubyPackages_3_3.rubocop
    rubyPackages_3_3.pry
  ];
}
