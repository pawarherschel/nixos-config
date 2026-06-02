# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    base16.url = "github:SenchoPens/base16.nix";
    den.url = "github:denful/den";
    flake-file.url = "github:vic/flake-file";
    flake-parts = {
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
      url = "github:hercules-ci/flake-parts";
    };
    helium-browser = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:ominit/helium-browser-flake";
    };
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/release-26.05";
    };
    import-tree.url = "github:vic/import-tree";
    nil-src = {
      flake = false;
      url = "github:oxalica/nil/504599f7e555a249d6754698473124018b80d121";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-lib.follows = "nixpkgs";
    stylix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/stylix/release-25.11";
    };
    tt-schemes = {
      flake = false;
      url = "github:tinted-theming/schemes";
    };
  };

}
