# Resolve paths inside a theme.
# Usage:
#   kernix-theme-path                -> current theme directory
#   kernix-theme-path <theme>        -> theme directory
#   kernix-theme-path <theme> <file> -> file inside the theme

data_dir="${KERNIX_PATH:-$HOME/.local/share/kernix}"
themes_dir="$data_dir/themes"

theme="${1:-$(kernix-theme-current 2>/dev/null || true)}"
theme="${theme,,}"
theme="${theme// /-}"

if [[ -z "$theme" ]]; then
  echo "Error: no theme set and none provided" >&2
  exit 1
fi

theme_dir="$themes_dir/$theme"
if [[ ! -d "$theme_dir" ]]; then
  echo "Error: theme '$theme' not found" >&2
  exit 1
fi

if [[ $# -ge 2 ]]; then
  echo "$theme_dir/$2"
else
  echo "$theme_dir"
fi
