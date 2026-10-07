{
  description = "kernix-theme -- runtime theme engine and theme pack for Home Manager.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = f:
      nixpkgs.lib.genAttrs systems (system:
        f {pkgs = nixpkgs.legacyPackages.${system};});
  in {
    # ── Shared library ──
    # Consume as: inputs.kernix-theme.lib.theme { inherit pkgs config; }
    lib = {
      theme = import ./lib/theme.nix;
      packages = import ./lib/packages.nix;
      schema = args: import ./lib/schema.nix args;
      apps = import ./apps;
      scripts = ./scripts;
      themes = ./themes;
    };

    # ── Home Manager module ──
    homeManagerModules = {
      default = import ./modules;
      theme = import ./modules;
    };

    # ── Standalone CLI bundle (nix run / nix build) ──
    # Includes the core tools plus every builtin app's adapter, and the
    # wallpaper engine. KERNIX_PATH defaults to ~/.local/share/kernix.
    packages = forAllSystems ({pkgs}: let
      kernixPath = "$HOME/.local/share/kernix";
      themeLib = import ./lib/theme.nix {
        inherit pkgs;
        dataDir = kernixPath;
      };
      appPkgs = pkgs.lib.concatMap (a:
        if (a.provide or null) == null
        then []
        else a.provide {inherit pkgs themeLib;})
      (builtins.attrValues (import ./apps));
    in {
      default = pkgs.symlinkJoin {
        name = "kernix-theme";
        paths =
          (import ./lib/packages.nix {
            inherit pkgs kernixPath;
            wallpaper.enable = true;
          })
          ++ appPkgs;
      };
    });

    # ── Checks (bash syntax of generated fragments) ──
    checks = forAllSystems ({pkgs}: let
      themeLib = import ./lib/theme.nix {
        inherit pkgs;
        dataDir = "$HOME/.local/share/kernix";
      };
      schema = import ./lib/schema.nix {lib = pkgs.lib; inherit pkgs themeLib;};
      builtin = import ./apps;
      appsFile = builtins.concatStringsSep "\n" (map schema.mkFragment (builtins.attrValues builtin));
    in {
      fragments = pkgs.runCommand "kernix-theme-fragments" {} ''
        set -euo pipefail
        cat > apps.sh <<'EOF'
        ${appsFile}
      EOF
        bash -n apps.sh
        echo "fragments OK" > $out
      '';
    });

    formatter = forAllSystems ({pkgs}: pkgs.alejandra);
  };
}