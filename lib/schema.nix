# kernix-theme app schema and code generator.
#
# An "app" is the unit of abstraction: a typed list of actions plus optional
# native-name mapping, reload commands and packages. This module provides the
# option types, the builtin/user merge, and the shell-fragment generator that
# compiles enabled apps into sourceable shell functions.
{
  lib,
  pkgs,
  themeLib,
}: let
  inherit (lib) mkOption types;

  # ── Action primitives ──
  #   link   source (theme file) -> target   (symlink)
  #   copy   source (theme file) -> target   (copy; for apps that rewrite)
  #   render target, render fn               (per-theme Nix-rendered file, linked)
  #   run    command                         (escape hatch; command <theme> <dir> <value>)
  actionType = types.submodule {
    options = {
      type = mkOption {
        type = types.enum ["link" "copy" "render" "run"];
        description = "Action primitive.";
      };
      source = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "File name inside the active theme directory (link/copy).";
      };
      target = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Destination path; ~ is expanded at runtime.";
      };
      command = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Command to run (run). Receives <theme> <theme_dir> <value>.";
      };
      render = mkOption {
        type = types.nullOr (types.functionTo types.str);
        default = null;
        description = "Function { theme, palette, value } -> file contents (render).";
      };
    };
  };

  appType = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether the app is themed.";
      };
      priority = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Apply ordering (lower runs first). Inherited from the builtin when null.";
      };
      stubDirs = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Directories to create before applying.";
      };
      map = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Theme name -> app-native name overrides.";
      };
      default = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Fallback native name when no mapping matches.";
      };
      reload = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Shell commands run after all apps are applied.";
      };
      provide = mkOption {
        type = types.nullOr (types.functionTo (types.listOf types.package));
        default = null;
        description = "Function { pkgs, themeLib } -> packages to install for this app.";
      };
      actions = mkOption {
        type = types.listOf actionType;
        default = [];
        description = "Actions to run when this app's theme is applied.";
      };
    };
  };

  # Merge a builtin definition with a user override (user wins where set).
  resolveApp = name: builtin: user: {
    inherit name;
    enable =
      if user ? enable
      then user.enable
      else (builtin.enable or true);
    priority =
      if (user.priority or null) != null
      then user.priority
      else (builtin.priority or 50);
    stubDirs = (builtin.stubDirs or []) ++ (user.stubDirs or []);
    map = (builtin.map or {}) // (user.map or {});
    default =
      if (user.default or null) != null
      then user.default
      else (builtin.default or null);
    reload = (builtin.reload or []) ++ (user.reload or []);
    provide =
      if (user.provide or null) != null
      then user.provide
      else (builtin.provide or null);
    actions =
      if (user.actions or []) != []
      then user.actions
      else (builtin.actions or []);
  };

  # Native name for a theme, honouring theme-side and app-side maps.
  # Precedence: palette [theme.map].<app> ?? app.map.<theme> ?? app.default ?? theme.
  resolveValue = app: theme: let
    pal = themeLib.palette theme;
    themeMap = pal.theme.map or {};
    v1 = themeMap.${app.name} or null;
    v2 = app.map.${theme} or null;
    def = app.default or null;
  in
    if v1 != null
    then v1
    else if v2 != null
    then v2
    else if def != null
    then def
    else theme;

  actionLine = app: action:
    if action.type == "link"
    then ''      kernix_link "$theme_dir/${action.source}" ${lib.escapeShellArg action.target}
    ''
    else if action.type == "copy"
    then ''      kernix_copy "$theme_dir/${action.source}" ${lib.escapeShellArg action.target}
    ''
    else if action.type == "run"
    then ''      kernix_run ${lib.escapeShellArg action.command} "$theme" "$theme_dir" "$value"
    ''
    else if action.type == "render"
    then let
      cases = lib.concatMapStrings (theme: let
        value = resolveValue app theme;
        text = action.render {
          inherit theme value;
          palette = themeLib.palette theme;
          app = app.name;
        };
        out = pkgs.writeText "kernix-${app.name}-${theme}" text;
      in "    ${lib.escapeShellArg theme}) kernix_put ${lib.escapeShellArg (toString out)} ${lib.escapeShellArg action.target} ;;\n")
      themeLib.themeNames;
    in ''
      case "$theme" in
      ${cases}  esac
    ''
    else "";

  # Shell function names must be valid identifiers.
  fnName = name: "kernix_app_" + builtins.replaceStrings ["-" "."] ["_" "_"] name;

  # Compile one app into a shell function.
  mkFragment = app: let
    fn = fnName app.name;
    needsValue = lib.any (a: a.type == "run") app.actions;
    valueCase =
      lib.concatMapStrings (theme: "    ${lib.escapeShellArg theme}) value=${lib.escapeShellArg (resolveValue app theme)} ;;\n")
      themeLib.themeNames;
    valueDefault =
      if app.default != null
      then lib.escapeShellArg app.default
      else "\"$theme\"";
    valueBlock =
      if needsValue
      then ''
        local value
        case "$theme" in
        ${valueCase}  *) value=${valueDefault} ;;
        esac
      ''
      else "";
    stubs = lib.concatMapStrings (d: "  kernix_mkdir \"${d}\"\n") app.stubDirs;
    actions = lib.concatMapStrings (actionLine app) app.actions;
    reloads = lib.concatMapStrings (r: "  kernix_reload ${lib.escapeShellArg r}\n") app.reload;
  in ''
    kernix_app_names+=(${lib.escapeShellArg fn})
    ${fn}() {
      local theme="$1" theme_dir="$2"
    ${valueBlock}${stubs}${actions}${reloads}
    }

  '';

  # All destination paths an app touches, for stub creation.
  stubTargets = app:
    lib.unique
    (lib.concatMap (a:
      lib.optional (a ? target && a.target != null) a.target)
    app.actions);
in {
  inherit actionType appType resolveApp resolveValue mkFragment stubTargets;
}
