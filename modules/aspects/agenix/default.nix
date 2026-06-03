# agenix — age-encrypted secrets for NixOS
{ den, inputs, ... }:
{
  flake-file.inputs = {
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.agenix = {
    includes = [
      den.aspects.agenix.agenix-rekey
    ];

    nixos =
      { pkgs, ... }:
      {
        imports = [
          inputs.agenix.nixosModules.age
        ];


      };
  };
}
