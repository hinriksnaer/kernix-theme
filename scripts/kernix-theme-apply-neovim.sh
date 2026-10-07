# Apply theme to all running neovim instances via RPC.
# Called by kernix-theme-apply as a script hook.
# Usage: kernix-theme-apply-neovim <theme-name> <theme-path>

if [[ $# -lt 2 ]]; then
    exit 1
fi

theme_path="$2"
nvim_source="$theme_path/neovim.lua"

if [[ ! -f "$nvim_source" ]]; then
    exit 1
fi

# Build lua command to load the theme spec
lua_cmd="local ok, spec = pcall(dofile, [[${nvim_source}]]); if ok and spec then for _, s in ipairs(spec) do if type(s) == 'table' and s.config then pcall(s.config, nil, s.opts or {}) end end end"

# Find neovim server sockets
uid="$(id -u)"

set +e
for sock in /run/user/"$uid"/nvim.*.0 /tmp/nvim*/0; do
    if [[ -S "$sock" ]]; then
        nvim --server "$sock" --remote-send ":lua $lua_cmd<CR>" &>/dev/null
    fi
done
set -e

exit 0
