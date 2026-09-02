# cli.devenv — devenv cache substituters and the devenv CLI.
_: {
  den.aspects.cli.devenv = {
    nixos =
      { pkgs, ... }:
      {
        nix.settings = {
          extra-substituters = [ "https://devenv.cachix.org" ];
          extra-trusted-public-keys = [ "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" ];
        };

        environment.systemPackages = [ pkgs.devenv ];
      };
  };
}