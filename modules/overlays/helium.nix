# Adds helium browser to nixpkgs.
{ inputs, den, ... }:
let
  helium-browser = inputs.helium-browser;
in
{
  flake-file.inputs.helium-browser = {
    url = "github:ominit/helium-browser-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.overlays.helium.nixos.nixpkgs.overlays = [
    (final: prev: {
      helium = helium-browser.packages.${prev.system}.helium;
    })
  ];
}
