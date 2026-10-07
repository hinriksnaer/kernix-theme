# Builtin app registry. Each file is a pure definition consumed by the engine;
# `kernix.theme.hooks = [ "btop" ];` enables these by name, and
# `kernix.theme.apps.<name>` overrides or adds to them.
{
  btop = import ./btop.nix;
  ghostty = import ./ghostty.nix;
  herdr = import ./herdr.nix;
  hyprland = import ./hyprland.nix;
  hyprlock = import ./hyprlock.nix;
  kitty = import ./kitty.nix;
  mako = import ./mako.nix;
  neovim = import ./neovim.nix;
  opencode = import ./opencode.nix;
  rofi = import ./rofi.nix;
  waybar = import ./waybar.nix;
  yazi = import ./yazi.nix;
}
