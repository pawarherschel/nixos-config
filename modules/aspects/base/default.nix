# base — minimal config every host gets: unfree + cli.
{ den, lib, ... }:
{
  den.aspects.base = {
    includes = [ den.aspects.cli ];

    nixos = {
      nixpkgs.config.allowUnfree = true;
      hardware.enableRedistributableFirmware = lib.mkDefault true;
    };
  };
}
