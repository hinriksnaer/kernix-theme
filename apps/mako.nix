{
  priority = 24;
  actions = [
    {
      type = "link";
      source = "mako.ini";
      target = "~/.config/mako/theme.conf";
    }
  ];
  reload = ["pkill -f mako; sleep 0.3; setsid mako >/dev/null 2>&1 &"];
}
