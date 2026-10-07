{
  priority = 21;
  actions = [
    {
      type = "link";
      source = "kitty.conf";
      target = "~/.config/kitty/theme.conf";
    }
  ];
  reload = ["pkill -SIGUSR1 kitty"];
}
