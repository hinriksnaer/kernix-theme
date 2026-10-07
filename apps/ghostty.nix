{
  priority = 21;
  actions = [
    {
      type = "link";
      source = "ghostty.conf";
      target = "~/.config/ghostty/theme";
    }
  ];
  reload = ["busctl --user call com.mitchellh.ghostty /com/mitchellh/ghostty org.gtk.Actions Activate sava{sv} reload-config 0 0"];
}
