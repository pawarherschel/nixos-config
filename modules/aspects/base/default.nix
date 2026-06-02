# base — minimal config every host gets: unfree + cli.
{ den, ... }:
{
  den.aspects.base = {
    includes = [ den.aspects.cli ];

    nixos.nixpkgs.config.allowUnfree = true;
  };
}
