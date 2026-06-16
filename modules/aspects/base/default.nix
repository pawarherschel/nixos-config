# base — minimal config every host gets: unfree + cli.
{ den, lib, ... }:
{
  den.aspects.base = {
    includes = [
      den.aspects.cli
      den.aspects.agenix
    ];

    nixos = {
      nixpkgs.config.allowUnfree = true;
      hardware.enableRedistributableFirmware = lib.mkDefault true;
    };
  };
}
