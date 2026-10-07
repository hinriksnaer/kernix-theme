# Get the currently active theme
# Usage: kernix-theme-current

state_file="$HOME/.config/kernix/current-theme"

if [[ -f "$state_file" ]]; then
    theme_name="$(< "$state_file")"
    theme_name="${theme_name#"${theme_name%%[![:space:]]*}"}"
    theme_name="${theme_name%"${theme_name##*[![:space:]]}"}"
    if [[ -n "$theme_name" ]]; then
        echo "$theme_name"
        exit 0
    fi
fi

# No theme set
echo ""
exit 1
