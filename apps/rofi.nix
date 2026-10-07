{
  priority = 22;
  actions = [
    {
      type = "link";
      source = "rofi.rasi";
      target = "~/.config/rofi/theme.rasi";
    }
  ];
  provide = {
    pkgs,
    themeLib,
  }: [
    (themeLib.mkScript {
      name = "kernix-rofi-theme-select";
      runtimeInputs = with pkgs; [rofi coreutils gnused libnotify];
    })
    (themeLib.mkScript {
      name = "kernix-rofi-wallpaper-select";
      runtimeInputs = with pkgs; [rofi swaybg findutils coreutils gnugrep gnused procps libnotify];
    })
  ];
}
