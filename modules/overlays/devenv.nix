# Adds devenv to nixpkgs.
{ inputs, ... }:
{
  flake-file.inputs.devenv = {
    url = "github:cachix/devenv";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.overlays.devenv.nixos.nixpkgs.overlays = [
    (_final: prev: {
      devenv = inputs.devenv.packages.${prev.system}.devenv;
    })
  ];
}
