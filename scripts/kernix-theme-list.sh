# List all available themes in the themes directory
# Usage: kernix-theme-list

data_dir="${KERNIX_PATH:-$HOME/.local/share/kernix}"
themes_dir="$data_dir/themes"

if [[ ! -d "$themes_dir" ]]; then
  echo "Error: Themes directory not found: $themes_dir" >&2
  exit 1
fi

for theme_dir in "$themes_dir"/*/; do
  [[ -d "$theme_dir" ]] || continue
  basename "$theme_dir"
done | sort
