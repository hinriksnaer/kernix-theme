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
  lib ? pkgs.lib,
  config ? {},
  dataDir ? "${config.home.homeDirectory}/.local/share/kernix",
}: let
  scripts = ../scripts;
  themesDir = ../themes;

  # Every directory in themes/ is a theme. `palette.toml` is optional.
  themeNames =
    lib.attrNames
    (lib.filterAttrs (_: type: type == "directory") (builtins.readDir themesDir));

  palettePath = name: themesDir + "/${name}/palette.toml";

  # Parsed palette for a theme, or {} when the theme has none.
  palette = name:
    let
      path = palettePath name;
    in
      if builtins.pathExists path
      then builtins.fromTOML (builtins.readFile path)
      else {};

  # Wrap a script from scripts/ as a derivation. `env` entries are exported
  # before the script body and may reference shell variables ($HOME).
  mkScript = {
    name,
    runtimeInputs ? [],
    env ? {},
    excludeShellChecks ? [],
  }:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      inherit excludeShellChecks;
      text = ''
        export KERNIX_PATH="''${KERNIX_PATH:-${kernixPath}}"
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "export ${k}=${lib.escapeShellArg v}") env)}
        ${builtins.readFile "${scripts}/${name}.sh"}
      '';
    };
in rec {
  inherit scripts themesDir themeNames palette palettePath mkScript;
  kernixPath = dataDir;
}
