# Core kernix-theme CLI tools.
#
# These are always installed by the Home Manager module. App-specific tools
# (neovim/yazi/herdr adapters, rofi pickers) are provided by each app's
# `provide` function instead.
#
# `wallpaper` controls the optional wallpaper commands and bakes the chosen
# backend/target into the wrappers.
{
  pkgs,
  kernixPath,
  wallpaper ? {
    enable = false;
    backend = "swaybg";
    target = "$HOME/.config/hypr/wallpapers/current";
  },
}: let
  themeLib = import ./theme.nix {
    inherit pkgs;
    dataDir = kernixPath;
  };
  inherit (themeLib) mkScript;
  lib = pkgs.lib;

  kwpBackend = wallpaper.backend or "swaybg";
  kwpTarget = wallpaper.target or "$HOME/.config/hypr/wallpapers/current";

  wallpaperEnv = {
    KERNIX_WALLPAPER_BACKEND = kwpBackend;
    KERNIX_WALLPAPER_TARGET = kwpTarget;
  };
in
  [
    (mkScript {
      name = "kernix-theme-apply";
      runtimeInputs = with pkgs; [coreutils gnused findutils];
      excludeShellChecks = ["SC2129"];
    })
    (mkScript {
      name = "kernix-theme-set";
      runtimeInputs = with pkgs; [coreutils gnused libnotify];
    })
    (mkScript {
      name = "kernix-theme-current";
      runtimeInputs = with pkgs; [coreutils];
    })
    (mkScript {
      name = "kernix-theme-list";
      runtimeInputs = with pkgs; [coreutils];
    })
    (mkScript {
      name = "kernix-theme-path";
      runtimeInputs = with pkgs; [coreutils];
    })
    (mkScript {name = "kernix-theme-next";})
    (mkScript {name = "kernix-theme-prev";})
    (mkScript {name = "kernix-theme-refresh";})
    (mkScript {
      name = "kernix-theme";
      runtimeInputs = with pkgs; [coreutils gnused fzf];
    })
  ]
  ++ lib.optionals wallpaper.enable [
    (mkScript {
      name = "kernix-wallpaper-set";
      runtimeInputs = with pkgs; [swaybg coreutils findutils procps];
      env = wallpaperEnv;
      excludeShellChecks = ["SC2016"];
    })
    (mkScript {
      name = "kernix-wallpaper-next";
      runtimeInputs = with pkgs; [swaybg coreutils findutils procps libnotify];
      env = wallpaperEnv;
      excludeShellChecks = ["SC2016"];
    })
    (mkScript {
      name = "kernix-wallpaper-list";
      runtimeInputs = with pkgs; [coreutils findutils gnugrep];
      env = wallpaperEnv;
      excludeShellChecks = ["SC2016"];
    })
    (mkScript {
      name = "kernix-wallpaper-set-file";
      runtimeInputs = with pkgs; [swaybg coreutils procps];
      env = wallpaperEnv;
      excludeShellChecks = ["SC2016"];
    })
  ]
