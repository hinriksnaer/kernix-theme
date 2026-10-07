# Interactive CLI theme selector using fzf
# Perfect for terminal-only environments
# Usage: kernix-theme

# Get list of available themes
mapfile -t theme_list < <(kernix-theme-list)

if [[ ${#theme_list[@]} -eq 0 ]]; then
    echo "No themes found"
    exit 1
fi

# Get current theme (may fail, that's ok)
current_theme="$(kernix-theme-current 2>/dev/null || true)"

# Prepare theme list with current indicator
display_list=()
for theme in "${theme_list[@]}"; do
    if [[ "$theme" == "$current_theme" ]]; then
        display_list+=("● $theme (current)")
    else
        display_list+=("  $theme")
    fi
done

# Show fzf selector with preview
selected="$(printf '%s\n' "${display_list[@]}" | \
    fzf --height=40% \
        --reverse \
        --border=rounded \
        --prompt="Select theme > " \
        --header="Use ↑↓ to navigate, Enter to select, Esc to cancel" \
        --preview="echo 'Theme: {}' | sed 's/^[● ]*//' " || true)"

# Extract theme name from selection (remove indicator and "(current)")
if [[ -n "$selected" ]]; then
    theme_name="$(echo "$selected" | sed 's/^[● ]*//' | sed 's/ (current)$//')"

    echo ""
    echo "Applying theme: $theme_name"
    kernix-theme-set "$theme_name"
else
    echo "Theme selection cancelled"
fi
