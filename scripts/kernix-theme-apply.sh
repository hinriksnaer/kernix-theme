# Unified theme hook processor -- applies theme to all registered apps.
# Reads hook definitions from ~/.config/kernix/theme-hooks.d/ and processes
# them in sorted order. Handles symlink, hyprland, config-rewrite, and script types.
# Usage: kernix-theme-apply <theme-name>

hooks_dir="$HOME/.config/kernix/theme-hooks.d"

# Output helpers
C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_RED='\033[0;31m'

success() { echo -e "${C_GREEN}✓${C_RESET} $*"; }
warning() { echo -e "${C_YELLOW}⊘${C_RESET} $*"; }
error()   { echo -e "${C_RED}✗${C_RESET} $*"; }

if [[ $# -lt 1 ]]; then
    echo "Usage: kernix-theme-apply <theme-name>"
    exit 1
fi

# Find themes directory
if [[ -n "${KERNIX_PATH:-}" ]] && [[ -d "$KERNIX_PATH/themes" ]]; then
    themes_dir="$KERNIX_PATH/themes"
else
    themes_dir="$HOME/.local/share/kernix/themes"
fi

theme_name="${1,,}"             # lowercase
theme_name="${theme_name// /-}" # spaces to dashes

if [[ ! -d "$themes_dir/$theme_name" ]]; then
    error "Theme '$theme_name' does not exist"
    exit 1
fi

theme_path="$themes_dir/$theme_name"
applied_count=0
skipped_count=0
reload_names=()
reload_commands=()

# Process hook files (sorted alphanumerically)
if [[ ! -d "$hooks_dir" ]]; then
    warning "No theme hooks directory at $hooks_dir"
    echo "0:0"
    exit 0
fi

# Need to handle commands that may fail without tripping set -e
set +e

for hook_file in "$hooks_dir"/*; do
    [[ -f "$hook_file" ]] || continue

    hook_name="$(basename "$hook_file" | sed 's/^[0-9]*-//')"
    source_file=""
    target_path=""
    reload_cmd=""
    hook_type="symlink"
    config_key=""
    hook_script=""

    # Parse hook file
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Trim whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        # Skip empty lines and comments
        [[ -z "$line" ]] && continue
        [[ "$line" == \#* ]] && continue

        k="${line%%=*}"
        k="${k#"${k%%[![:space:]]*}"}"
        k="${k%"${k##*[![:space:]]}"}"
        val="${line#*=}"
        val="${val#"${val%%[![:space:]]*}"}"
        val="${val%"${val##*[![:space:]]}"}"

        case "$k" in
            source) source_file="$val" ;;
            target) target_path="$(eval echo "$val")" ;;
            reload) reload_cmd="$val" ;;
            type)   hook_type="$val" ;;
            key)    config_key="$val" ;;
            script) hook_script="$val" ;;
        esac
    done < "$hook_file"

    # ── symlink type ──
    if [[ "$hook_type" == "symlink" ]]; then
        if [[ -z "$source_file" ]] || [[ -z "$target_path" ]]; then
            skipped_count=$((skipped_count + 1))
            warning "Skipped $hook_name (missing source or target)"
            continue
        fi
        if [[ -f "$theme_path/$source_file" ]]; then
            mkdir -p "$(dirname "$target_path")" 2>/dev/null
            ln -sf "$theme_path/$source_file" "$target_path"
            applied_count=$((applied_count + 1))
            success "Applied $hook_name"
        else
            skipped_count=$((skipped_count + 1))
            warning "Skipped $hook_name ($source_file not in theme)"
        fi

    # ── hyprland type ──
    elif [[ "$hook_type" == "hyprland" ]]; then
        if [[ -f "$theme_path/hyprland.lua" ]]; then
            cp "$theme_path/hyprland.lua" "$HOME/.config/hypr/active-theme.lua"
            applied_count=$((applied_count + 1))
            success "Applied $hook_name"
        else
            skipped_count=$((skipped_count + 1))
            warning "Skipped $hook_name (no hyprland.lua in theme)"
        fi

    # ── config-rewrite type ──
    elif [[ "$hook_type" == "config-rewrite" ]]; then
        if [[ -n "$target_path" ]] && [[ -n "$config_key" ]]; then
            if [[ -f "$target_path" ]]; then
                sed -i "s/\"$config_key\": *\"[^\"]*\"/\"$config_key\": \"$theme_name\"/" "$target_path"
                applied_count=$((applied_count + 1))
                success "Applied $hook_name"
            else
                skipped_count=$((skipped_count + 1))
                warning "Skipped $hook_name ($target_path not found)"
            fi
        else
            skipped_count=$((skipped_count + 1))
            warning "Skipped $hook_name (missing target or key)"
        fi

    # ── script type ──
    elif [[ "$hook_type" == "script" ]]; then
        if [[ -z "$hook_script" ]]; then
            skipped_count=$((skipped_count + 1))
            warning "Skipped $hook_name (no script specified)"
            continue
        fi
        # Skip if script not available or source file specified but missing
        if ! command -v "$hook_script" &>/dev/null; then
            skipped_count=$((skipped_count + 1))
            warning "Skipped $hook_name ($hook_script not found)"
            continue
        fi
        if [[ -n "$source_file" ]] && [[ ! -f "$theme_path/$source_file" ]]; then
            skipped_count=$((skipped_count + 1))
            warning "Skipped $hook_name ($source_file not in theme)"
            continue
        fi
        if "$hook_script" "$theme_name" "$theme_path"; then
            applied_count=$((applied_count + 1))
            success "Applied $hook_name"
        else
            skipped_count=$((skipped_count + 1))
            warning "Skipped $hook_name (script failed)"
        fi

    else
        skipped_count=$((skipped_count + 1))
        warning "Skipped $hook_name (unknown type: $hook_type)"
    fi

    # Queue reload command
    if [[ -n "$reload_cmd" ]]; then
        reload_names+=("$hook_name")
        reload_commands+=("$reload_cmd")
    fi
done

# Execute reload commands
if [[ ${#reload_commands[@]} -gt 0 ]]; then
    echo ""
    for i in "${!reload_commands[@]}"; do
        cmd="${reload_commands[i]}"
        name="${reload_names[i]}"
        eval "$cmd" &>/dev/null &
        disown 2>/dev/null
        success "Reloaded $name"
    done
fi

set -e

# Summary
pretty_name="$(echo "$theme_name" | sed 's/-/ /g; s/\b\(.\)/\u\1/g')"
echo ""
echo "╭────────────────────────────────────────╮"
echo "│ Theme: $pretty_name"
echo "│ Applied: $applied_count  •  Skipped: $skipped_count"
echo "╰────────────────────────────────────────╯"
echo ""
