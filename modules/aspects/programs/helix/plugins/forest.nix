# forest.hx uses Git and filesystem commands for its tree operations.
{ ... }:
{
  den.aspects.programs.helix.homeManager =
    { pkgs, ... }:
    {
      programs.nhx = {
        requiredPackages = [
          pkgs.git
          pkgs.coreutils # mv and mkdir
        ];
        plugins.forest.enable = true;
      };
    };
}
