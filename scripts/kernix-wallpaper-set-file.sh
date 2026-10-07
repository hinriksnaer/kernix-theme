# Set a specific wallpaper file using the configured backend.
# Usage: kernix-wallpaper-set-file <path-to-image>
# Backend and target come from KERNIX_WALLPAPER_BACKEND / KERNIX_WALLPAPER_TARGET
# (baked into the wrappers by the module; defaults: swaybg / hypr wallpapers).

path="$1"
if [[ -z "$path" ]] || [[ ! -f "$path" ]]; then
  echo "Error: no such wallpaper: $path" >&2
  exit 1
fi

target="${KERNIX_WALLPAPER_TARGET:-$HOME/.config/hypr/wallpapers/current}"
target="${target/#\~/$HOME}"
backend="${KERNIX_WALLPAPER_BACKEND:-swaybg}"

mkdir -p "$(dirname "$target")"
ln -sf "$(realpath "$path")" "$target"

case "$backend" in
  hyprpaper)
    if command -v hyprctl >/dev/null 2>&1; then
      hyprctl hyprpaper preload "$path" >/dev/null 2>&1 || true
      hyprctl hyprpaper wallpaper ",$path" >/dev/null 2>&1 || true
    fi
    ;;
  swaybg | *)
    old_pids="$(pgrep -x swaybg || true)"
    swaybg -i "$target" -m fill >/dev/null 2>&1 &
    disown 2>/dev/null || true
    sleep 0.5
    for pid in $old_pids; do
      kill "$pid" 2>/dev/null || true
    done
    ;;
esac

echo "✓ Wallpaper set to: $(basename "$path")"