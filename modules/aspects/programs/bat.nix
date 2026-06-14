# bat — cat replacement with syntax highlighting.
_: {
  den.aspects.programs.bat = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.bat ];
      };

    provides.ksakura.homeManager.programs.bat.enable = true;
  };
}
