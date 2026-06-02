# syncthing — file sync service.
{ den, ... }:
{
  den.aspects.programs.syncthing = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.syncthing ];
      };

    homeManager.services.syncthing.enable = true;
  };
}
