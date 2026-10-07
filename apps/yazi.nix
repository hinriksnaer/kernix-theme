{
  priority = 12;
  provide = {pkgs, themeLib}: [
    (themeLib.mkScript {
      name = "kernix-theme-apply-yazi";
      runtimeInputs = with pkgs; [coreutils gnugrep];
    })
  ];
  actions = [
    {type = "run"; command = "kernix-theme-apply-yazi";}
  ];
}
