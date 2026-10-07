# Shared helpers for the kernix-theme engine.
#
# Call with:
#   themeLib = import <kernix-theme>/lib/theme.nix { inherit pkgs config; };
#
# `dataDir` is where the deployed theme pack lives at runtime (the engine
# module installs it via xdg.dataFile."kernix/themes"). It defaults to the
# Home Manager data directory; pass it explicitly when no HM config exists.
{
  pkgs,
  config ? {},
  dataDir ? "${config.home.homeDirectory}/.local/share/kernix",
}: let
  scripts = ../scripts;
in rec {
  kernixPath = dataDir;
  inherit scripts;

  mkScript = name: runtimeInputs:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = ''
        export KERNIX_PATH="${kernixPath}"
        ${builtins.readFile "${scripts}/${name}.sh"}
      '';
    };
}
