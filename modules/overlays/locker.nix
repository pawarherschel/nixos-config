# Adds locker to nixpkgs.
{ inputs, ... }:
let
  inherit (inputs) locker;
in
{
  flake-file.inputs.locker = {
    url = "github:tgirlcloud/locker";
  };

  den.aspects.overlays.locker.nixos.nixpkgs.overlays = [
    (final: prev: {
      locker = locker.packages.${prev.stdenv.hostPlatform.system}.default;
    })
  ];
}
