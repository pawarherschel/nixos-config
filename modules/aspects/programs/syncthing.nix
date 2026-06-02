# syncthing — file sync service.
_: {
  den.aspects.programs.syncthing = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.syncthing ];
      };

    homeManager.services.syncthing.enable = true;
  };
}
