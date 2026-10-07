{
  priority = 10;
  actions = [
    {
      type = "link";
      source = "btop.theme";
      target = "~/.config/btop/themes/active.theme";
    }
  ];
  reload = ["pkill -SIGUSR2 btop"];
}
