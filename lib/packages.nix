# All kernix-theme CLI tools as derivations.
#
# `kernixPath` is baked into each wrapper as KERNIX_PATH, pointing at the
# deployed theme pack. The HM module passes the Home Manager data dir; the
# flake's `packages` output passes a $HOME-relative default so the tools
# also work outside Home Manager.
#
# `hooks` selects optional components so hosts only pull in what their stack
# needs. Pass `null` (default) to include everything (standalone bundle):
#   - neovim/yazi/herdr adapters are gated on their own hook
#   - wallpaper scripts are gated on the "hyprland" hook
#   - rofi pickers are gated on the "rofi" hook
{
  pkgs,
  kernixPath,
  hooks ? null,
}: let
  themeLib = import ./theme.nix {
    inherit pkgs;
    dataDir = kernixPath;
  };
  inherit (themeLib) mkScript scripts;
  lib = pkgs.lib;
  enabled = name: hooks == null || lib.elem name hooks;
in
  # ── Core engine (always) ──
  [
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
  ]
  # ── App apply adapters ──
  ++ lib.optionals (enabled "neovim") [
    (mkScript "kernix-theme-apply-neovim" (with pkgs; [neovim coreutils]))
  ]
  ++ lib.optionals (enabled "yazi") [
    (mkScript "kernix-theme-apply-yazi" (with pkgs; [coreutils gnugrep]))
  ]
  ++ lib.optionals (enabled "herdr") [
    (mkScript "kernix-theme-apply-herdr" (with pkgs; [coreutils gnused]))
  ]
  # ── Wallpaper engine (Hyprland) ──
  ++ lib.optionals (enabled "hyprland") [
    (mkScript "kernix-wallpaper-set" (with pkgs; [swaybg coreutils findutils procps]))
    (mkScript "kernix-wallpaper-next" (with pkgs; [swaybg coreutils findutils procps libnotify]))
  ]
  # ── Rofi pickers ──
  ++ lib.optionals (enabled "rofi") [
    (mkScript "kernix-rofi-theme-select" (with pkgs; [rofi coreutils gnused libnotify]))
    (mkScript "kernix-rofi-wallpaper-select" (with pkgs; [rofi swaybg findutils coreutils gnugrep gnused procps libnotify]))
  ]
