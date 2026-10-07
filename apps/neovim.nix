{
  priority = 11;
  provide = {
    pkgs,
    themeLib,
  }: [
    (themeLib.mkScript {
      name = "kernix-theme-apply-neovim";
      runtimeInputs = with pkgs; [neovim coreutils];
    })
  ];
  actions = [
    {
      type = "run";
      command = "kernix-theme-apply-neovim";
    }
  ];
}
