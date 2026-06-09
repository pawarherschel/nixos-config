# Adds helium browser to nixpkgs.
{ inputs, ... }:
let
  inherit (inputs) helium-browser;
in
{
  flake-file.inputs.helium-browser = {
    url = "github:ominit/helium-browser-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.overlays.helium.nixos.nixpkgs.overlays = [
    (_final: prev: {
      helium = helium-browser.packages.${prev.stdenv.hostPlatform.system}.helium;
    })
  ];
}
