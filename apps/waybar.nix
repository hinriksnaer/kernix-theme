{
  priority = 20;
  actions = [
    {
      type = "link";
      source = "waybar.css";
      target = "~/.config/waybar/theme.css";
    }
  ];
  reload = ["pkill waybar; sleep 0.3; waybar &disown"];
}
