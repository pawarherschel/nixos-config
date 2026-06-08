# Adds opencode to nixpkgs.
{ inputs, ... }:
let
  llm-agents = inputs.opencode-flake;
in
{
  flake-file.inputs.opencode-flake = {
    url = "github:numtide/llm-agents.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.overlays.opencode.nixos.nixpkgs.overlays = [
    (_final: prev: {
      opencode = llm-agents.packages.${prev.system}.opencode;
    })
  ];
}
