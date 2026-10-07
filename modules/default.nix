# kernix-theme -- runtime theme engine for Home Manager.
#
# Apps opt into theming by adding their hook name to `kernix.theme.hooks`:
#
#   kernix.theme.hooks = [ "btop" "neovim" ];
#
# Hook definitions live in hooks/<name>.nix (pure data, one file per app).
# The engine generates hook registrations (~/.config/kernix/theme-hooks.d/*)
# and file stubs from the enabled set.
{
  pkgs,
  config,
  lib,
  host ? {},
  ...
}: let
  themeLib = import ../lib/theme.nix {inherit pkgs config;};
  inherit (themeLib) kernixPath;

  cfg = config.kernix.theme;

  # ── Hook registry ──
  # Load a hook definition by name from hooks/<name>.nix.
  loadHook = name: import ../hooks/${name}.nix;

  # Build the hook text for a single hook definition.
  hookText = def: let
    lines =
      lib.optional (def ? type) "type=${def.type}"
      ++ lib.optional (def ? script) "script=${def.script}"
      ++ lib.optional (def ? source) "source=${def.source}"
      ++ lib.optional (def ? target) "target=${def.target}"
      ++ lib.optional (def ? key) "key=${def.key}"
      ++ lib.optional (def ? reload) "reload=${def.reload}";
  in
    builtins.concatStringsSep "\n" lines;

  # Build the stub activation script for a hook that has a target.
  # Hook targets use ~ which must be expanded to $HOME at runtime.
  stubScript = def: let
    mkdirs = builtins.concatStringsSep "\n" (map (d: ''mkdir -p "${d}"'') (def.stubDirs or []));
  in ''
    ${mkdirs}
    _stub_target="${def.target}"
    _stub_target="''${_stub_target/#\~/$HOME}"
    mkdir -p "$(dirname "$_stub_target")"
    [ -e "$_stub_target" ] || touch "$_stub_target"
  '';

  # All enabled hook definitions (loaded from hooks/).
  enabledHooks = map (name: {inherit name;} // loadHook name) cfg.hooks;

  # Hook registrations (xdg.configFile entries).
  hookFiles = builtins.listToAttrs (map (h: {
      name = "kernix/theme-hooks.d/${h.priority}-${h.name}";
      value.text = hookText h;
    })
    enabledHooks);

  # Stub activations (home.activation entries for hooks with targets).
  stubActivations = builtins.listToAttrs (lib.concatMap (h:
    lib.optional (h ? target) {
      name = "${h.name}ThemeStub";
      value = config.lib.dag.entryAfter ["linkGeneration"] (stubScript h);
    })
  enabledHooks);
in {
  # ── Option declaration ──
  options.kernix.theme = {
    hooks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of theme hook names to enable (must match a file in kernix-theme/hooks/).";
    };

    defaultTheme = lib.mkOption {
      type = lib.types.str;
      default = "ayu";
      description = "Theme seeded into ~/.config/kernix/current-theme on first activation.";
    };
  };

  config = {
    # ── Hook registrations + stubs ──
    xdg.configFile =
      hookFiles
      // lib.optionalAttrs (lib.elem "yazi" cfg.hooks) {
        # Yazi flavor mapping travels with the engine when its hook is enabled.
        "yazi/theme-map.conf".source = ../theme-map.conf;
      };
    home.activation =
      stubActivations
      // {
        # ── Default theme seeding ──
        kernixConfig = config.lib.dag.entryAfter ["linkGeneration"] ''
          mkdir -p "$HOME/.config/kernix"
          if [ ! -f "$HOME/.config/kernix/current-theme" ]; then
            echo "${host.defaultTheme or cfg.defaultTheme}" > "$HOME/.config/kernix/current-theme"
          fi
        '';
      };

    # ── Engine + adapters + pickers ──
    home.packages = import ../lib/packages.nix {
      inherit pkgs kernixPath;
      hooks = cfg.hooks;
    };

    home.sessionVariables.KERNIX_PATH = kernixPath;

    # ── Theme data deployment ──
    xdg.dataFile."kernix/themes".source = ../themes;
  };
}
