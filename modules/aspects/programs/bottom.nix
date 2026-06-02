# bottom — system monitor.
{ den, ... }:
{
  den.aspects.programs.bottom = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.bottom ];
      };

    homeManager = {
      programs.bottom = {
        enable = true;
        settings.flags = { };
      };
    };
  };
}
