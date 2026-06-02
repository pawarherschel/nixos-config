# wsl — minimal CLI host.
{ den, ... }:
{
  den.aspects.wsl.includes = [ den.aspects.base ];

  den.aspects.wsl.nixos.system.stateVersion = "23.05";
}
