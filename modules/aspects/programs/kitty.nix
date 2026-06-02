# kitty — terminal emulator.
{ den, ... }:
{
  den.aspects.programs.kitty = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.kitty ];
      };

    homeManager = {
      programs.kitty = {
        enable = true;
        # font = {
        #   package = pkgs.jetbrains-mono;
        #   name = "JetBrainsMono NF Regular";
        #   size = 11;
        # };
        settings.window_padding_width = 15;
      };
    };
  };
}
