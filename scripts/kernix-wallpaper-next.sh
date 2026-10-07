# Cycle through wallpapers in the current theme
# Usage: kernix-wallpaper-next
# Uses swaybg

# Find themes directory using active profile
if [[ -n "${KERNIX_PATH:-}" ]] && [[ -d "$KERNIX_PATH/themes" ]]; then
    themes_dir="$KERNIX_PATH/themes"
else
    notify-send "Error" "Active profile not found" -t 3000 -u critical 2>/dev/null || true
    exit 1
fi

current_wallpaper_link="$HOME/.config/hypr/wallpapers/current"

# Get current theme from API
theme_name="$(kernix-theme-current 2>/dev/null || true)"
if [[ -z "$theme_name" ]]; then
    notify-send "Wallpaper Error" "No theme set" -t 3000 -u critical 2>/dev/null || true
    exit 1
fi

backgrounds_dir="$themes_dir/$theme_name/backgrounds"

# Check if backgrounds directory exists
if [[ ! -d "$backgrounds_dir" ]]; then
    notify-send "No Wallpapers" "Theme '$theme_name' has no backgrounds" -t 3000 2>/dev/null || true
    exit 1
fi

# Get all background images (sorted)
mapfile -t backgrounds < <(find -L "$backgrounds_dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) 2>/dev/null | sort)

if [[ ${#backgrounds[@]} -eq 0 ]]; then
    notify-send "No Wallpapers" "No images found in theme backgrounds" -t 3000 2>/dev/null || true
    # Set black background
    pkill -x swaybg 2>/dev/null || true
    swaybg --color '#000000' &>/dev/null &
    disown
    exit 1
fi

# Get current wallpaper from symlink
current_wallpaper=""
if [[ -L "$current_wallpaper_link" ]]; then
    current_wallpaper="$(readlink -f "$current_wallpaper_link")"
fi

# Find current wallpaper index (0-indexed)
current_index=-1
for i in "${!backgrounds[@]}"; do
    if [[ "${backgrounds[i]}" == "$current_wallpaper" ]]; then
        current_index=$i
        break
    fi
done

# Get next wallpaper (wrap around)
next_index=$(( (current_index + 1) % ${#backgrounds[@]} ))

new_wallpaper="${backgrounds[next_index]}"

# Create wallpapers directory if needed and set new wallpaper symlink
mkdir -p "$(dirname "$current_wallpaper_link")"
ln -sf "$new_wallpaper" "$current_wallpaper_link"

# Start new swaybg, wait for render, kill old one
old_pids="$(pgrep -x swaybg || true)"
swaybg -i "$current_wallpaper_link" -m fill &>/dev/null &
disown
sleep 0.5
for pid in $old_pids; do
    kill "$pid" 2>/dev/null || true
done

wallpaper_name="$(basename "$new_wallpaper")"
notify-send "Wallpaper Changed" "$wallpaper_name" -t 2000 2>/dev/null || true

echo "Wallpaper set to: $wallpaper_name"
