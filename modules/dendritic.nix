# den + flake-file wiring. nixpkgs and home-manager kept in sync.
{ inputs, ... }:
{
  imports = [
    (inputs.flake-file.flakeModules.dendritic or { })
    (inputs.den.flakeModules.dendritic or { })
    inputs.agenix-rekey.flakeModule
    inputs.home-manager.flakeModules.home-manager
  ];

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  flake-file.inputs = {
    den.url = "github:denful/den";
    flake-file.url = "github:vic/flake-file";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
