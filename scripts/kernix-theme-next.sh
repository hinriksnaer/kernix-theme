# Cycle to the next theme in the list
# Usage: kernix-theme-next

mapfile -t available_themes < <(kernix-theme-list)

if [[ ${#available_themes[@]} -eq 0 ]]; then
    echo "Error: No themes found"
    exit 1
fi

current_theme="$(kernix-theme-current 2>/dev/null || true)"

# If can't determine current, use last theme (so next will be first)
if [[ -z "$current_theme" ]]; then
    current_theme="${available_themes[-1]}"
fi

# Find current theme index (0-indexed)
current_index=-1
for i in "${!available_themes[@]}"; do
    if [[ "${available_themes[i]}" == "$current_theme" ]]; then
        current_index=$i
        break
    fi
done

# Get next theme (wrap around)
next_index=$(( (current_index + 1) % ${#available_themes[@]} ))

kernix-theme-set "${available_themes[next_index]}"
