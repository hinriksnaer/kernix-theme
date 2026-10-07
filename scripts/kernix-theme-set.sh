# Set a specific theme by name.
# Thin orchestrator: writes state, applies apps, sets wallpaper, notifies.
# Usage: kernix-theme-set <theme-name>

if [[ $# -lt 1 ]]; then
  echo "Usage: kernix-theme-set <theme-name>"
  echo ""
  echo "Available themes:"
  kernix-theme-list
  exit 1
fi

theme_name="${1,,}"           # lowercase
theme_name="${theme_name// /-}" # spaces to dashes

data_dir="${KERNIX_PATH:-$HOME/.local/share/kernix}"
themes_dir="$data_dir/themes"

if [[ ! -d "$themes_dir/$theme_name" ]]; then
  echo "Error: Theme '$theme_name' does not exist"
  echo ""
  echo "Available themes:"
  kernix-theme-list
  exit 1
fi

# 1. Write global state
mkdir -p "$HOME/.config/kernix"
echo "$theme_name" > "$HOME/.config/kernix/current-theme"

# 2. Apply all apps (streams output in real-time)
kernix-theme-apply "$theme_name"

# 3. Set wallpaper (if available)
if command -v kernix-wallpaper-set >/dev/null 2>&1; then
  kernix-wallpaper-set "$theme_name" >/dev/null 2>&1 || true
fi

# 4. Send notification (if available)
if command -v notify-send >/dev/null 2>&1; then
  pretty_name="$(echo "$theme_name" | sed 's/-/ /g; s/\b\(.\)/\u\1/g')"
  notify-send "Theme Changed" "Switched to: $pretty_name" -t 3000 2>/dev/null || true
fi