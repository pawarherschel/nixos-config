# den.default — applied to every host and user automatically.
{
  lib,
  den,
  self,
  inputs,
  ...
}:
let
  common = {
    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
in
{
  den = {
    default = {
      homeManager.home.stateVersion = "26.05";

      includes = [
        den.batteries.hostname
        (den.batteries.define-user { })
      ];

      nixos = {
        imports = [ common ];
        nix.channel.enable = false;

        home-manager = {
          backupFileExtension = "bk";
          useGlobalPkgs = true;
        };

        # Capture the full flake source in the system closure.
        # `../.` resolves from this file (modules/defaults.nix) to the flake root.
        # This is a Nix store path, safe from accidental local deletion.
        environment.etc."nixos-config" = {
          source = ../.;
        };

        # Tag the generation with the git/jj revision.
        # Uses self.rev when available (for flakes fetched via git+file:// or a forge).
        # Falls back to "dirty" for local path flakes (no git metadata in pure eval).
        system.configurationRevision = lib.mkDefault (inputs.self.rev or self.rev or "dirty");
      };

      darwin = {
        imports = [ common ];
        system.stateVersion = 7;
      };
    };

    schema.user.classes = lib.mkDefault [ "homeManager" ];
  };
}
