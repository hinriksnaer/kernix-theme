# Wallpaper selector with image previews using rofi grid layout.
# Purely a frontend: listing and applying delegate to the wallpaper engine.

CURRENT_THEME=$(kernix-theme-current 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

mapfile -t WALLPAPERS < <(kernix-wallpaper-list "$CURRENT_THEME" 2>/dev/null || true)

if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
  notify-send "Wallpaper Selector" "No wallpapers for theme: $CURRENT_THEME" -t 3000
  exit 1
fi

target="${KERNIX_WALLPAPER_TARGET:-$HOME/.config/hypr/wallpapers/current}"
target="${target/#\~/$HOME}"
CURRENT_WALLPAPER=$(readlink -f "$target" 2>/dev/null || true)

MENU_ITEMS=""
for wp in "${WALLPAPERS[@]}"; do
  resolved=$(readlink -f "$wp")
  name=$(basename "$wp" | sed 's/\.[^.]*$//; s/\.[^.]*$//; s/-/ /g; s/_/ /g')
  if [[ "$resolved" == "$CURRENT_WALLPAPER" ]]; then
    MENU_ITEMS+="* $name\x00icon\x1f$resolved\n"
  else
    MENU_ITEMS+="  $name\x00icon\x1f$resolved\n"
  fi
done

SELECTED=$(echo -e "$MENU_ITEMS" | rofi -dmenu \
  -i \
  -p "Wallpaper" \
  -show-icons \
  -theme-str 'window {width: 80%; height: 70%;}' \
  -theme-str 'mainbox {padding: 20px;}' \
  -theme-str 'listview {columns: 4; lines: 2; flow: horizontal; fixed-columns: true; fixed-lines: true; spacing: 20px;}' \
  -theme-str 'element {orientation: vertical; padding: 10px; spacing: 8px; border-radius: 10px;}' \
  -theme-str 'element-icon {size: 20%; border-radius: 8px;}' \
  -theme-str 'element-text {horizontal-align: 0.5;}' \
  -theme-str 'inputbar {padding: 12px; margin: 0 0 20px 0; border-radius: 8px;}')

if [[ -z "$SELECTED" ]]; then
  exit 0
fi

SELECTED_CLEAN="${SELECTED#\* }"
SELECTED_CLEAN="${SELECTED_CLEAN#"${SELECTED_CLEAN%%[![:space:]]*}"}"

SELECTED_PATH=""
for wp in "${WALLPAPERS[@]}"; do
  name=$(basename "$wp" | sed 's/\.[^.]*$//; s/\.[^.]*$//; s/-/ /g; s/_/ /g')
  if [[ "$name" == "$SELECTED_CLEAN" ]]; then
    SELECTED_PATH="$wp"
    break
  fi
done

if [[ -n "$SELECTED_PATH" ]]; then
  nohup kernix-wallpaper-set-file "$SELECTED_PATH" &>/dev/null &
  notify-send "Wallpaper Changed" "$(basename "$SELECTED_PATH")" -t 2000
fi