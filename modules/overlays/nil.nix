# Overrides nil to a pinned revision.
#
# To update: change rev + cargoHash, then nix flake update nil-src

{ inputs, ... }:
let
  rev = "504599f7e555a249d6754698473124018b80d121";
  cargoHash = "sha256-LS2IW4gZ1k6Xl5weMNwxvVA2z56r4rPkjqrkROZTmBw=";
in
{
  flake-file.inputs.nil-src = {
    url = "github:oxalica/nil/${rev}";
    flake = false;
  };

  den.aspects.overlays.nil.nixos =
    { config, ... }:
    let
      inherit (inputs) nil-src;
    in
    {
      nixpkgs.overlays = [
        (final: prev: {
          nil = (prev.nil.override { nix = config.nix.package; }).overrideAttrs (
            finalAttrs: _previousAttrs: {
              src = nil-src;
              cargoDeps = final.rustPlatform.fetchCargoVendor {
                inherit (finalAttrs) src;
                hash = cargoHash;
              };
            }
          );
        })
      ];
    };
}
