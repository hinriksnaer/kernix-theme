{
  priority = 14;
  provide = {
    pkgs,
    themeLib,
  }: [
    (themeLib.mkScript {
      name = "kernix-theme-apply-herdr";
      runtimeInputs = with pkgs; [coreutils gnused];
    })
  ];
  actions = [
    {
      type = "run";
      command = "kernix-theme-apply-herdr";
    }
  ];
  default = "terminal";
}
