# kernix-theme -- runtime theme engine for Home Manager.
#
# Apps opt into theming by adding their hook name to `kernix.theme.hooks`:
#
#   kernix.theme.hooks = [ "btop" "neovim" ];
#
# or by declaring a full app (used by third-party flakes):
#
#   kernix.theme.apps.myapp = {
#     actions = [ { type = "render"; target = "..."; render = { palette, ... }: "..."; } ];
#   };
#
# Enabled apps are compiled into ~/.config/kernix/apps.sh, which
# kernix-theme-apply sources and runs.
{
  pkgs,
  config,
  lib,
  host ? {},
  ...
}: let
  themeLib = import ../lib/theme.nix {inherit pkgs config;};
  inherit (themeLib) kernixPath;
  schema = import ../lib/schema.nix {inherit lib pkgs themeLib;};
  builtin = import ../apps;

  cfg = config.kernix.theme;

  appNames = lib.unique (cfg.hooks ++ builtins.attrNames cfg.apps);
  resolve = name: schema.resolveApp name (builtin.${name} or {}) (cfg.apps.${name} or {});
  allApps = map resolve appNames;
  enabledApps = builtins.filter (a: a.enable) allApps;
  sortedApps = lib.sort (a: b: a.priority < b.priority) enabledApps;

  appsFile = builtins.concatStringsSep "\n" (map schema.mkFragment sortedApps);

  corePkgs = import ../lib/packages.nix {
    inherit pkgs kernixPath;
    inherit (cfg) wallpaper;
  };
  appPkgs = lib.concatMap (a:
    if a.provide == null
    then []
    else a.provide {inherit pkgs themeLib;})
  enabledApps;

  stubTargets = lib.unique (lib.concatMap schema.stubTargets enabledApps);
  stubDirs = lib.unique (lib.concatMap (a: a.stubDirs) enabledApps);
  stubScript = lib.concatStringsSep "\n" (
    map (d: ''mkdir -p "${d}"'') stubDirs
    ++ map (t: ''
      _kernix_stub=${lib.escapeShellArg t}
      _kernix_stub="''${_kernix_stub/#\~/$HOME}"
      mkdir -p "$(dirname "$_kernix_stub")"
      [ -e "$_kernix_stub" ] || : > "$_kernix_stub"
    '')
    stubTargets
  );
in {
  # ── Options ──
  options.kernix.theme = {
    selected = lib.mkOption {
      type = lib.types.str;
      default = "ayu";
      description = "Theme seeded into ~/.config/kernix/current-theme on first activation.";
    };

    hooks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Builtin app names to enable (see kernix-theme/apps/).";
    };

    apps = lib.mkOption {
      type = lib.types.attrsOf schema.appType;
      default = {};
      description = "App definitions; extends or overrides the builtin registry.";
    };

    packages = {
      engine = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        readOnly = true;
        default = corePkgs;
        description = ''
          The core CLI tools (kernix-theme-*, kernix-wallpaper-*) as an
          explicit dependency. Orchestration layers (launcher pickers,
          widgets, scripts) should consume this rather than relying on the
          ambient PATH.
        '';
      };
    };

    wallpaper = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install and enable wallpaper management.";
      };
      backend = lib.mkOption {
        type = lib.types.enum ["swaybg" "hyprpaper"];
        default = "swaybg";
        description = "Wallpaper backend.";
      };
      target = lib.mkOption {
        type = lib.types.str;
        default = "$HOME/.config/hypr/wallpapers/current";
        description = "Path the current wallpaper is linked to.";
      };
    };
  };

  # ── Wiring ──
  config = {
    xdg.configFile."kernix/apps.sh".text = appsFile;
    xdg.dataFile."kernix/themes".source = ../themes;

    home.packages = corePkgs ++ appPkgs;

    home.sessionVariables = {
      KERNIX_PATH = kernixPath;
      KERNIX_WALLPAPER_BACKEND = cfg.wallpaper.backend;
      KERNIX_WALLPAPER_TARGET = cfg.wallpaper.target;
    };

    home.activation = {
      kernixConfig = config.lib.dag.entryAfter ["linkGeneration"] ''
        mkdir -p "$HOME/.config/kernix"
        if [ ! -f "$HOME/.config/kernix/current-theme" ]; then
          printf '%s\n' "${host.defaultTheme or cfg.selected}" > "$HOME/.config/kernix/current-theme"
        fi
      '';

      kernixStubs = config.lib.dag.entryAfter ["linkGeneration"] stubScript;
    };
  };
}
