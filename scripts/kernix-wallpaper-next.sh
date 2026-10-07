# Cycle through wallpapers in the current theme.
# Usage: kernix-wallpaper-next

theme="$(kernix-theme-current 2>/dev/null || true)"
if [[ -z "$theme" ]]; then
  notify-send "Wallpaper Error" "No theme set" -t 3000 -u critical 2>/dev/null || true
  exit 1
fi

mapfile -t backgrounds < <(kernix-wallpaper-list "$theme" 2>/dev/null || true)
if [[ ${#backgrounds[@]} -eq 0 ]]; then
  notify-send "No Wallpapers" "Theme '$theme' has no backgrounds" -t 3000 2>/dev/null || true
  exit 1
fi

target="${KERNIX_WALLPAPER_TARGET:-$HOME/.config/hypr/wallpapers/current}"
target="${target/#\~/$HOME}"

current="$(readlink -f "$target" 2>/dev/null || true)"

current_index=-1
for i in "${!backgrounds[@]}"; do
  if [[ "${backgrounds[i]}" == "$current" ]]; then
    current_index=$i
    break
  fi
done

next_index=$(( (current_index + 1) % ${#backgrounds[@]} ))
new_wallpaper="${backgrounds[next_index]}"

kernix-wallpaper-set-file "$new_wallpaper"
notify-send "Wallpaper Changed" "$(basename "$new_wallpaper")" -t 2000 2>/dev/null || true
echo "Wallpaper set to: $(basename "$new_wallpaper")"