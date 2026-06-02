# bat — cat replacement with syntax highlighting.
{ den, ... }:
{
  den.aspects.programs.bat = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.bat ];
      };

    homeManager.programs.bat.enable = true;
  };
}
