# kernix-theme

A runtime theme engine and theme pack for Home Manager. Apps opt in via
`kernix.theme.hooks` (builtins) or `kernix.theme.apps.<name>` (custom apps).
Enabled apps are compiled into `~/.config/kernix/apps.sh`, which
`kernix-theme-apply` sources and runs whenever the theme changes.

Each theme is a plain directory of per-app files plus a `palette.toml`
describing colors and native-name mappings:

```
themes/<name>/
├── palette.toml      # name, colors, [theme.map], [wallpaper]
├── ghostty.conf      # app files by name
├── hyprland.lua
├── rofi.rasi
└── ...
```

## Consuming the flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    kernix-theme.url = "github:hinriksnaer/kernix-theme";
  };

  outputs = {nixpkgs, kernix-theme, ...}: {
    homeConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        # ...
        kernix-theme.homeManagerModules.theme
        ({host, ...}: {
          kernix.theme.selected = host.defaultTheme; # seed only
          kernix.theme.hooks = ["btop" "neovim" "rofi"]; # rofi = link rofi.rasi
          kernix.theme.wallpaper = {
            enable = true;
            backend = "swaybg";
          };
        })
      ];
    };
  };
}
```

Run `kernix-theme-set <theme>` to switch, or `kernix-theme` for the fzf
picker. Wallpapers: `kernix-wallpaper-set` / `-next` / `-list` /
`-set-file`.

## The runtime ABI

`kernix-theme-apply <theme>`:

1. reads `$KERNIX_PATH` (default `~/.local/share/kernix`)
2. sources `~/.config/kernix/apps.sh`
3. calls each registered `kernix_app_*` function with `(<theme> <theme_dir>)`
4. runs any queued reload commands

Generated app functions call one of five engine primitives:

| Primitive   | Meaning                                                        |
| ----------- | -------------------------------------------------------------- |
| `kernix_link`  | symlink `<theme_dir>/<source>` -> `target`                   |
| `kernix_copy`  | copy file (for targets that get rewritten in place)          |
| `kernix_put`   | link a Nix-store file produced by a `render` action          |
| `kernix_run`   | run `command <theme> <theme_dir> <value>`                    |
| `kernix_mkdir` | create a directory before applying                           |

Targets use `~` which is expanded against `$HOME` at runtime. Sources missing
from the theme directory are skipped (counted in the apply summary).

The engine treats `render` as an early-return for that app: the Nix case
supplies per-theme store files (with the app's value resolved at eval) and
links the match to the target.

## Enablement vs orchestration

Two interfaces, deliberately separate:

- **Enablement** — `kernix.theme.hooks` / `kernix.theme.apps.<name>` plus the
  action primitives. The engine applies theme files (`link`/`copy`/`render`)
  when a theme changes. A builtin app's `provide` belongs here too: it ships
  *apply-time* adapters (the `run` action) that fire during
  `kernix-theme-apply`.
- **Orchestration** — UI/scripts that let the user *drive* the engine
  (launcher pickers, widgets, keybinds) by calling the installed
  `kernix-theme-*` / `kernix-wallpaper-*` CLI. This is the consumer's job and
  is **not** part of the theme pack.

To build orchestration, depend on the engine explicitly via
`config.kernix.theme.packages.engine` instead of relying on the ambient
`$PATH`:

```nix
{ config, pkgs, ... }: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "my-theme-picker";
      runtimeInputs = [pkgs.fzf] ++ config.kernix.theme.packages.engine;
      text = "kernix-theme-list | fzf | xargs -r kernix-theme-set";
    })
  ];
}
```

## App actions

An app is a priority, a list of actions, optional reloads and (for builtins)
a package `provide` function. `provide` returns extra packages for the app —
**builtins** use `themeLib.mkScript` (which reads
`kernix-theme/scripts/<name>.sh`); **consumers** ship their own scripts with
`pkgs.writeShellApplication`:

```nix
kernix.theme.apps.alacritty = {
  priority = 21;
  actions = [
    {
      type = "link";
      source = "alacritty.yml";
      target = "~/.config/alacritty/theme.yml";
    }
  ];
  reload = ["alacritty msg config --path ~/.config/alacritty/theme.yml"];
  provide = {pkgs, ...}: [
    (pkgs.writeShellApplication {
      name = "kernix-theme-apply-alacritty";
      runtimeInputs = with pkgs; [coreutils alacritty];
      text = ''alacritty msg config --path "$HOME/.config/alacritty/theme.yml"'';
    })
  ];
};
```

User apps merge over the builtin registry by name: `enable`, `priority`,
`map`, `default`, `reload`, `provide`, `stubDirs`, and `actions` are all
overridable from the consumer side.

### Action types

- **`link`** — `source` (+ `target`): symlink a theme file to a config path.
  Prefer this: works with `nix --store` rebuilds and zero-copy.
- **`copy`** — for apps that would otherwise rewrite the symlink target.
- **`render`** — `target` + `render = {theme, value, palette, app} -> text`.
  Produces a per-theme Nix-store file; ideal when the config is JSON/Toml
  derived from the palette.
- **`run`** — `command`: escape hatch for complex adapters
  (e.g. `kernix-theme-apply-neovim`). Receives `<theme> <theme_dir> <value>`.

### Native-name resolution

`resolveValue` picks the name an app should use for a theme, in order:

1. `palette.toml [theme.map].<app>` (theme-side, recommended)
2. app `map.<theme>`
3. app `default`
4. the theme name itself

Example (`themes/catppuccin/palette.toml`): `[theme.map] yazi = "catppuccin-mocha"`
makes yazi resolve to its pre-built flavor instead of the raw theme name.

## Themes

Add `themes/<name>/` with the files your enabled apps reference, plus a
`palette.toml`:

```toml
name = "My Theme"
variant = "dark"

[colors]
bg = "#1e1e2e"
fg = "#cdd6f4"
# ...

[theme.map]
yazi = "my-flavor"
herdr = "myname"

[wallpaper]
# one or more files; kernix-wallpaper-list picks the first by sort order
```

`kernix-theme-list` discovers themes by directory. The standalone bundle
(`nix build` / `nix run` on this flake) ships the core CLI plus every builtin
app's adapter with `$HOME`-relative `KERNIX_PATH`, for testing outside Home
Manager.

## Builtin apps

`apps/` holds the builtin registry: `btop`, `ghostty`, `herdr`, `hyprland`,
`hyprlock`, `kitty`, `mako`, `neovim`, `opencode`, `rofi`, `waybar`, `yazi`.
Each exports `{priority, actions, reload?, provide?, map?, default?}` and is
merged with consumer overrides via `schema.resolveApp`.

## Development

- `nix build .#checks.x86_64-linux.fragments` — `bash -n` on the generated
  `apps.sh` (the output *is* the file).
- `nix build .#default` — standalone CLI bundle (shellcheck all scripts).
- `lib/schema.nix` — action/app option types, value resolution, fragment
  generator.
- `lib/theme.nix` — `palette`, `mkScript`, path helpers.