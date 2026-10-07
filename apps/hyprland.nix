{
  priority = 25;
  actions = [
    {
      type = "copy";
      source = "hyprland.lua";
      target = "~/.config/hypr/active-theme.lua";
    }
  ];
  reload = ["hyprctl reload"];
}
