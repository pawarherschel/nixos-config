# Adds pi coding agent to nixpkgs.
{ inputs, ... }:
let
  llm-agents = inputs.pi-coding-agent-flake;
in
{
  flake-file.inputs.pi-coding-agent-flake = {
    url = "github:numtide/llm-agents.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.overlays.pi-coding-agent.nixos.nixpkgs.overlays = [
    (_final: prev: {
      pi-coding-agent = llm-agents.packages.${prev.stdenv.hostPlatform.system}.pi;
    })
  ];
}
