# Unified theme hook processor -- applies the active theme to all registered apps.
# App registrations are compiled by Nix into ~/.config/kernix/apps.sh; this
# script sources that file, runs each app function, then runs queued reloads.
# Usage: kernix-theme-apply <theme-name>

apps_file="$HOME/.config/kernix/apps.sh"

C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_RED='\033[0;31m'

success() { echo -e "${C_GREEN}✓${C_RESET} $*"; }
warning() { echo -e "${C_YELLOW}⊘${C_RESET} $*"; }
error() { echo -e "${C_RED}✗${C_RESET} $*"; }

if [[ $# -lt 1 ]]; then
  echo "Usage: kernix-theme-apply <theme-name>"
  exit 1
fi

data_dir="${KERNIX_PATH:-$HOME/.local/share/kernix}"
themes_dir="$data_dir/themes"

theme_name="${1,,}"            # lowercase
theme_name="${theme_name// /-}" # spaces to dashes

if [[ ! -d "$themes_dir/$theme_name" ]]; then
  error "Theme '$theme_name' does not exist"
  exit 1
fi
theme_path="$themes_dir/$theme_name"

# ── State shared with generated app functions ──
kernix_app_names=()
kernix_reload_cmds=()
kernix_applied=0
kernix_skipped=0

kernix_expand() { printf '%s' "${1/#\~/$HOME}"; }
kernix_mkdir() { mkdir -p "$(kernix_expand "$1")"; }

kernix_link() {
  local src="$1" dst
  dst="$(kernix_expand "$2")"
  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    kernix_applied=$((kernix_applied + 1))
  else
    kernix_skipped=$((kernix_skipped + 1))
  fi
}

kernix_copy() {
  local src="$1" dst
  dst="$(kernix_expand "$2")"
  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp -f "$src" "$dst"
    kernix_applied=$((kernix_applied + 1))
  else
    kernix_skipped=$((kernix_skipped + 1))
  fi
}

kernix_put() {
  local src="$1" dst
  dst="$(kernix_expand "$2")"
  if [[ -n "$src" && -f "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    kernix_applied=$((kernix_applied + 1))
  else
    kernix_skipped=$((kernix_skipped + 1))
  fi
}

kernix_run() {
  local cmd="$1"
  shift
  if command -v "$cmd" >/dev/null 2>&1; then
    if "$cmd" "$@"; then
      kernix_applied=$((kernix_applied + 1))
    else
      kernix_skipped=$((kernix_skipped + 1))
    fi
  else
    kernix_skipped=$((kernix_skipped + 1))
  fi
}

kernix_reload() {
  kernix_reload_cmds+=("$1")
}

if [[ ! -f "$apps_file" ]]; then
  warning "No app registrations at $apps_file"
  exit 0
fi

# shellcheck source=/dev/null
source "$apps_file"

for fn in "${kernix_app_names[@]}"; do
  "$fn" "$theme_name" "$theme_path"
done

# Execute queued reload commands (detached).
if [[ ${#kernix_reload_cmds[@]} -gt 0 ]]; then
  echo ""
  for cmd in "${kernix_reload_cmds[@]}"; do
    bash -c "$cmd" >/dev/null 2>&1 &
    disown 2>/dev/null || true
    success "Reloaded"
  done
fi

# Summary
pretty_name="$(echo "$theme_name" | sed 's/-/ /g; s/\b\(.\)/\u\1/g')"
echo ""
echo "╭────────────────────────────────────────╮"
echo "│ Theme: $pretty_name"
echo "│ Applied: $kernix_applied  •  Skipped: $kernix_skipped"
echo "╰────────────────────────────────────────╯"
echo ""
