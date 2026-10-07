{
  priority = 23;
  actions = [
    {
      type = "link";
      source = "hyprlock.conf";
      target = "~/.config/hypr/hyprlock-theme.conf";
    }
  ];
  stubDirs = ["$HOME/.config/hypr"];
}
