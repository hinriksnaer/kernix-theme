{
  priority = 13;
  actions = [
    {
      type = "render";
      target = "~/.config/opencode/tui.json";
      render = {value, ...}:
        builtins.toJSON {
          "$schema" = "https://opencode.ai/tui.json";
          theme = value;
        };
    }
  ];
}
