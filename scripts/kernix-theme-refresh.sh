# Refresh/reapply the current theme (useful after config changes)
# Usage: kernix-theme-refresh

current_theme="$(kernix-theme-current 2>/dev/null || true)"

if [[ -n "$current_theme" ]]; then
    echo "Refreshing theme: $current_theme"
    kernix-theme-set "$current_theme"
else
    echo "Error: No theme is currently set"
    echo "Run 'kernix-theme-set <theme-name>' first"
    exit 1
fi
