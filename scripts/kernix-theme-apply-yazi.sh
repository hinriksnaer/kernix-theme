# Apply theme to yazi by mapping kernix theme name to a yazi flavor.
# Called by kernix-theme-apply as a run action.
# Usage: kernix-theme-apply-yazi <theme-name> <theme-path> <value>
# `value` is the app-native yazi flavor resolved by the engine
# (palette [theme.map].yazi, app map, or default).

if [[ $# -lt 3 ]]; then
  exit 1
fi

if ! command -v yazi >/dev/null 2>&1; then
  exit 1
fi

value="$3"
if [[ -z "$value" ]]; then
  value="catppuccin-mocha"
fi

theme_file="$HOME/.config/yazi/theme.toml"
mkdir -p "$(dirname "$theme_file")"
printf '%s\n' \
  '# Yazi Theme for Kernix' \
  '# Managed by kernix-theme-apply - Do not edit manually' \
  '' \
  '[flavor]' \
  "use = \"$value\"" \
  > "$theme_file" 2>/dev/null