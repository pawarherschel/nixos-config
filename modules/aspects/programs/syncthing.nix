# syncthing — file sync service.
_: {
  den.aspects.programs.syncthing = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.syncthing ];
      };

    provides.ksakura.homeManager.services.syncthing.enable = true;
  };
}
