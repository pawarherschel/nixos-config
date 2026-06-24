# Adds palapply to nixpkgs.
{ inputs, ... }:
let
  inherit (inputs) palapply;
in
{
  flake-file.inputs.palapply = {
    url = "github:pawarherschel/palapply";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.overlays.palapply.nixos.nixpkgs.overlays = [
    (_final: prev: {
      palapply = palapply.packages.${prev.stdenv.hostPlatform.system}.default;
    })
  ];
}
