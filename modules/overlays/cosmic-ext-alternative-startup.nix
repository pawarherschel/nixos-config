# Adds cosmic-ext-alternative-startup to nixpkgs using naersk.
{ inputs, ... }:
{
  flake-file.inputs = {
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cosmic-ext-alternative-startup = {
      url = "github:Drakulix/cosmic-ext-alternative-startup";
      flake = false;
    };
  };

  den.aspects.overlays.cosmic-ext-alternative-startup.nixos.nixpkgs.overlays = [
    (final: _prev: {
      cosmic-ext-alternative-startup =
        let
          naersk' = final.callPackage inputs.naersk { };
        in
        naersk'.buildPackage {
          pname = "cosmic-ext-alternative-startup";
          src = inputs.cosmic-ext-alternative-startup;
          buildInputs = with final; [ libxkbcommon ];
          nativeBuildInputs = with final; [ pkg-config ];
          meta.mainProgram = "cosmic-ext-alternative-startup";
        };
    })
  ];
}
