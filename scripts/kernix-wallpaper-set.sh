# Set the first wallpaper of a theme using the configured backend.
# Usage: kernix-wallpaper-set [theme-name]   (default: current theme)

theme="${1:-$(kernix-theme-current 2>/dev/null || true)}"
theme="${theme,,}"
theme="${theme// /-}"

if [[ -z "$theme" ]]; then
  echo "Error: no theme set and none provided" >&2
  exit 1
fi

first="$(kernix-wallpaper-list "$theme" 2>/dev/null | head -n1)"

target="${KERNIX_WALLPAPER_TARGET:-$HOME/.config/hypr/wallpapers/current}"
target="${target/#\~/$HOME}"

if [[ -z "$first" ]]; then
  echo "⊘ No wallpapers found for theme '$theme'"
  rm -f "$target"
  exit 0
fi

kernix-wallpaper-set-file "$first"