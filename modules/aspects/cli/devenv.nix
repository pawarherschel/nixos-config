# cli.devenv — devenv cache substituters and the devenv CLI.
_: {
  den.aspects.cli.devenv = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.devenv ];
      };
  };
}
