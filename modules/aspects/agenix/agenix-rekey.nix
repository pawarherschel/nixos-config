{ inputs, ... }:
let
  common =
    { config, pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.agenix-rekey.packages.${pkgs.stdenv.hostPlatform.system}.default
        pkgs.rage
      ];
      age.rekey.storageMode = "local";
      age.rekey.localStorageDir = inputs.self.outPath + "/secrets/rekeyed/${config.networking.hostName}";
    };
in
{
  flake-file.inputs = {
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.agenix.agenix-rekey = {
    nixos =
      { ... }:
      {
        imports = [
          common
          inputs.agenix-rekey.nixosModules.default
        ];
      };

    darwin =
      { pkgs, ... }:
      {
        imports = [
          common
          inputs.agenix-rekey.darwinModules.default
        ];

        environment.systemPackages = [
          inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.agenix
          pkgs.age
        ];
      };
  };
}
