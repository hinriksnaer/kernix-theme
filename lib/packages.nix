# All kernix-theme CLI tools as derivations.
#
# `kernixPath` is baked into each wrapper as KERNIX_PATH, pointing at the
# deployed theme pack. The HM module passes the Home Manager data dir; the
# flake's `packages` output passes a $HOME-relative default so the tools
# also work outside Home Manager.
{
  pkgs,
  kernixPath,
}: let
  themeLib = import ./theme.nix {
    inherit pkgs;
    dataDir = kernixPath;
  };
  inherit (themeLib) mkScript scripts;
in [
  # ── Core engine ──
  (mkScript "kernix-theme-set" (with pkgs; [coreutils gnused libnotify]))
  (pkgs.writeShellApplication {
    name = "kernix-theme-apply";
    runtimeInputs = with pkgs; [coreutils gnused findutils];
    excludeShellChecks = ["SC2129"];
    text = ''
      export KERNIX_PATH="${kernixPath}"
      ${builtins.readFile "${scripts}/kernix-theme-apply.sh"}
    '';
  })
  (mkScript "kernix-theme-current" (with pkgs; [coreutils]))
  (mkScript "kernix-theme-list" (with pkgs; [coreutils]))
  (mkScript "kernix-theme-next" [])
  (mkScript "kernix-theme-prev" [])
  (mkScript "kernix-theme-refresh" [])
  (mkScript "kernix-theme" (with pkgs; [coreutils gnused fzf]))

  # ── App apply adapters ──
  (mkScript "kernix-theme-apply-neovim" (with pkgs; [neovim coreutils]))
  (mkScript "kernix-theme-apply-yazi" (with pkgs; [coreutils gnugrep]))
  (mkScript "kernix-theme-apply-herdr" (with pkgs; [coreutils gnused]))

  # ── Wallpaper engine ──
  (mkScript "kernix-wallpaper-set" (with pkgs; [swaybg coreutils findutils procps]))
  (mkScript "kernix-wallpaper-next" (with pkgs; [swaybg coreutils findutils procps libnotify]))

  # ── Rofi pickers ──
  (mkScript "kernix-rofi-theme-select" (with pkgs; [rofi coreutils gnused libnotify]))
  (mkScript "kernix-rofi-wallpaper-select" (with pkgs; [rofi swaybg findutils coreutils gnugrep gnused procps libnotify]))
]
