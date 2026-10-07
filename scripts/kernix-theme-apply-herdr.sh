# Apply theme to herdr by updating config.toml's theme.name value.
# Called by kernix-theme-apply as a run action.
# Usage: kernix-theme-apply-herdr <theme-name> <theme-path> <value>
# `value` is the app-native herdr theme name resolved by the engine
# (palette [theme.map].herdr, app map, or "terminal").
# "terminal" inherits the ANSI palette from the host terminal.

if [[ $# -lt 3 ]]; then
  exit 1
fi

value="${3:-terminal}"
config_file="$HOME/.config/herdr/config.toml"

if [[ ! -f "$config_file" ]]; then
  exit 1
fi

# Update theme.name in config.toml (matches: name = "..." under the [theme] section)
sed -i "s/^name = \"[^\"]*\"/name = \"$value\"/" "$config_file"

exit 0