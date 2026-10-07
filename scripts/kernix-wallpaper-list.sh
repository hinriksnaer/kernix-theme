# List background images for a theme.
# Usage: kernix-wallpaper-list [theme-name]   (default: current theme)

theme="${1:-$(kernix-theme-current 2>/dev/null || true)}"
theme="${theme,,}"
theme="${theme// /-}"

if [[ -z "$theme" ]]; then
  echo "Error: no theme set and none provided" >&2
  exit 1
fi

data_dir="${KERNIX_PATH:-$HOME/.local/share/kernix}"
dir="$data_dir/themes/$theme/backgrounds"

if [[ ! -d "$dir" ]]; then
  exit 0
fi

find -L "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort