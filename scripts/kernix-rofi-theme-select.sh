# Interactive theme selector using rofi dmenu
# Usage: kernix-rofi-theme-select

themes_dir="${KERNIX_PATH:-$HOME/.local/share/kernix}/themes"

if [[ ! -d "$themes_dir" ]]; then
    notify-send "Theme Selector" "Themes directory not found" -t 3000
    exit 1
fi

# Get list of available themes
mapfile -t theme_list < <(kernix-theme-list)

# Get current theme for highlighting
current_theme="$(kernix-theme-current 2>/dev/null || true)"
current_theme="${current_theme,,}"
current_theme="${current_theme// /-}"

# Build display list with current marker and track index
display_list=()
current_index=-1
index=0
for theme in "${theme_list[@]}"; do
    if [[ "$theme" == "$current_theme" ]]; then
        display_list+=("● $theme")
        current_index=$index
    else
        display_list+=("  $theme")
    fi
    index=$((index + 1))
done

# Show rofi picker, pre-select current theme
rofi_args=(-dmenu -i -p "Select Theme" -no-custom -theme-str 'window {width: 400px; height: 500px;}')
if [[ $current_index -ge 0 ]]; then
    rofi_args+=(-selected-row "$current_index")
fi
selected="$(printf '%s\n' "${display_list[@]}" | rofi "${rofi_args[@]}" || true)"

if [[ -z "$selected" ]]; then
    exit 0
fi

# Clean selection and convert to theme name
theme_name="$(echo "$selected" | sed 's/^[● ] *//; s/ /-/g')"
theme_name="${theme_name,,}"

# Apply in background
nohup kernix-theme-set "$theme_name" &>/dev/null &
