{ pkgs, ... }:
let
  # clangd (unwrapped LLVM) looks for system headers on the non-existent NixOS
  # paths (/usr/include, …); gcc only works because its cc-wrapper injects the
  # store include dirs on every call. So we ask the wrapped gcc/g++ for the
  # exact include search paths they use (libc, gcc builtins, libstdc++) and turn
  # each into a clangd `-isystem` entry. Generated at build time from the actual
  # toolchain, so it covers every standard C/C++ header and never goes stale.
  clangdConfig = pkgs.runCommand "clangd-config.yaml" { nativeBuildInputs = [ pkgs.gcc ]; } ''
    {
      echo "CompileFlags:"
      echo "  Add:"
      {
        gcc -E -Wp,-v -xc   /dev/null 2>&1
        g++ -E -Wp,-v -xc++ /dev/null 2>&1
      } | sed -n '/search starts here:/,/End of search list/p' \
        | grep '^ /nix/' \
        | sed 's/^ *//' \
        | sort -u \
        | while IFS= read -r dir; do
            printf '    - -isystem\n    - %s\n' "$dir"
          done
    } > "$out"
  '';
in
{
  xdg.configFile."clangd/config.yaml".source = clangdConfig;
}
