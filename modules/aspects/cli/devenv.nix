# cli.devenv — devenv cache substituters and the devenv CLI.
_: {
  den.aspects.cli.devenv = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.devenv ];
      };
  };
}
