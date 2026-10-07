# Apply theme to yazi by mapping kernix theme name to a yazi flavor.
# Called by kernix-theme-apply as a script hook.
# Usage: kernix-theme-apply-yazi <theme-name> <theme-path>

if [[ $# -lt 1 ]]; then
    exit 1
fi

if ! command -v yazi &>/dev/null; then
    exit 1
fi

theme_name="$1"
theme_map="$HOME/.config/yazi/theme-map.conf"
yazi_flavor=""

# Look up flavor mapping
if [[ -f "$theme_map" ]]; then
    while IFS='=' read -r key value; do
        # Skip comments and blank lines
        [[ "$key" == \#* ]] && continue
        [[ -z "$key" ]] && continue
        if [[ "$key" == "$theme_name" ]]; then
            yazi_flavor="$value"
            break
        fi
    done < "$theme_map"
fi

# Fallback if no mapping found
if [[ -z "$yazi_flavor" ]]; then
    yazi_flavor="catppuccin-mocha"
fi

theme_file="$HOME/.config/yazi/theme.toml"
printf '%s\n' \
    '# Yazi Theme for Kernix' \
    '# Managed by kernix-theme-apply - Do not edit manually' \
    '' \
    '[flavor]' \
    "use = \"$yazi_flavor\"" \
    > "$theme_file" 2>/dev/null
