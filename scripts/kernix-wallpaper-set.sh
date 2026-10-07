# Set wallpaper from current theme (uses first wallpaper found)
# Usage: kernix-wallpaper-set [theme-name]
# If no theme-name provided, uses current theme
# Uses swaybg

# Find themes directory using active profile
if [[ -n "${KERNIX_PATH:-}" ]] && [[ -d "$KERNIX_PATH/themes" ]]; then
    themes_dir="$KERNIX_PATH/themes"
else
    echo "Error: Active profile not found"
    exit 1
fi

current_wallpaper_link="$HOME/.config/hypr/wallpapers/current"

# Determine theme name
if [[ $# -ge 1 ]]; then
    theme_name="${1,,}"
    theme_name="${theme_name// /-}"
else
    theme_name="$(kernix-theme-current 2>/dev/null || true)"
    if [[ -z "$theme_name" ]]; then
        echo "Error: No theme set and no theme name provided"
        exit 1
    fi
fi

backgrounds_dir="$themes_dir/$theme_name/backgrounds"

# Check if backgrounds directory exists
if [[ ! -d "$backgrounds_dir" ]]; then
    echo "⊘ No wallpapers found for theme '$theme_name'"
    # Clear current wallpaper link if it exists
    rm -f "$current_wallpaper_link"
    exit 0
fi

# Get first background image
first_wallpaper="$(find -L "$backgrounds_dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) 2>/dev/null | sort | head -1)"

if [[ -z "$first_wallpaper" ]]; then
    echo "⊘ No wallpaper images found in theme backgrounds"
    rm -f "$current_wallpaper_link"
    # Set black background if no wallpaper
    pkill -x swaybg 2>/dev/null || true
    swaybg --color '#000000' &>/dev/null &
    disown
    exit 0
fi

# Create wallpapers directory if needed and set wallpaper symlink
mkdir -p "$(dirname "$current_wallpaper_link")"
ln -sf "$first_wallpaper" "$current_wallpaper_link"

# Start new swaybg, wait for render, kill old one
old_pids="$(pgrep -x swaybg || true)"
swaybg -i "$current_wallpaper_link" -m fill &>/dev/null &
disown
sleep 0.5
for pid in $old_pids; do
    kill "$pid" 2>/dev/null || true
done

wallpaper_name="$(basename "$first_wallpaper")"
echo "✓ Wallpaper set to: $wallpaper_name"
