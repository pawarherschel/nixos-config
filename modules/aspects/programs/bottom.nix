# bottom — system monitor.
_: {
  den.aspects.programs.bottom = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.bottom ];
      };

    provides.ksakura.homeManager = {
      programs.bottom = {
        enable = true;
        settings.flags = { };
      };
    };
  };
}
