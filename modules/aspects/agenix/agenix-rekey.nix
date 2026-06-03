{ inputs, ... }:
{
  flake-file.inputs = {
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.agenix.agenix-rekey = {
    nixos =
      { pkgs, config, ... }:
      {
        imports = [
          inputs.agenix-rekey.nixosModules.default
        ];

        environment.systemPackages = [
          inputs.agenix-rekey.packages.${pkgs.stdenv.hostPlatform.system}.default
          pkgs.rage
        ];

        age.rekey.storageMode = "local";
        age.rekey.localStorageDir = inputs.self.outPath + "/secrets/rekeyed/${config.networking.hostName}";
      };
  };
}
