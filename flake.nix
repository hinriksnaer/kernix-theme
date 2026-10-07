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
      scripts = ./scripts;
      hooks = ./hooks;
      themes = ./themes;
      themeMap = ./theme-map.conf;
    };

    # ── Home Manager module ──
    homeManagerModules = {
      default = import ./modules;
      theme = import ./modules;
    };

    # ── Standalone CLI bundle (nix run / nix build) ──
    # KERNIX_PATH defaults to ~/.local/share/kernix and can be overridden
    # at runtime: KERNIX_PATH=/path kernix-theme-list
    packages = forAllSystems ({pkgs}: {
      default = pkgs.symlinkJoin {
        name = "kernix-theme";
        paths = import ./lib/packages.nix {
          inherit pkgs;
          kernixPath = "$HOME/.local/share/kernix";
        };
      };
    });

    formatter = forAllSystems ({pkgs}: pkgs.alejandra);
  };
}
