# Apply theme to herdr by updating config.toml's theme.name value.
# Called by kernix-theme-apply as a script hook.
# Usage: kernix-theme-apply-herdr <theme-name> <theme-path>
#
# Maps kernix theme names to herdr built-in themes. Themes without a
# direct herdr equivalent use "terminal" to inherit ANSI palette colors
# from the host terminal (which the kernix terminal hook already controls).

if [[ $# -lt 1 ]]; then
    exit 1
fi

theme_name="$1"
config_file="$HOME/.config/herdr/config.toml"

if [[ ! -f "$config_file" ]]; then
    exit 1
fi

# Map kernix theme -> herdr built-in theme
case "$theme_name" in
    catppuccin)       herdr_theme="catppuccin" ;;
    nord)             herdr_theme="nord" ;;
    rose-pine-dark)   herdr_theme="rose-pine" ;;
    tokyo-night)      herdr_theme="tokyo-night" ;;
    *)                herdr_theme="terminal" ;;
esac

# Update theme.name in config.toml
# Matches: name = "..." under the [theme] section
sed -i "s/^name = \"[^\"]*\"/name = \"$herdr_theme\"/" "$config_file"

exit 0
