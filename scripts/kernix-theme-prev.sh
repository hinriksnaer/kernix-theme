# Cycle to the previous theme in the list
# Usage: kernix-theme-prev

mapfile -t available_themes < <(kernix-theme-list)

if [[ ${#available_themes[@]} -eq 0 ]]; then
    echo "Error: No themes found"
    exit 1
fi

current_theme="$(kernix-theme-current 2>/dev/null || true)"

# If can't determine current, use second theme (so prev will be first)
if [[ -z "$current_theme" ]]; then
    if [[ ${#available_themes[@]} -gt 1 ]]; then
        current_theme="${available_themes[1]}"
    else
        current_theme="${available_themes[0]}"
    fi
fi

# Find current theme index (0-indexed)
current_index=0
for i in "${!available_themes[@]}"; do
    if [[ "${available_themes[i]}" == "$current_theme" ]]; then
        current_index=$i
        break
    fi
done

# Get previous theme (wrap around)
prev_index=$(( (current_index - 1 + ${#available_themes[@]}) % ${#available_themes[@]} ))

kernix-theme-set "${available_themes[prev_index]}"
