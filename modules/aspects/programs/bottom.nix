# bottom — system monitor.
_: {
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
