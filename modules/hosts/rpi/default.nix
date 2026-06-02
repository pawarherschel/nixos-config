# rpi — minimal headless host.
{ den, ... }:
{
  den.aspects.rpi.includes = [ den.aspects.base ];

  den.aspects.rpi.nixos.system.stateVersion = "23.05";
}
