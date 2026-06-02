# system.fstrim — SSD TRIM.
{ den, ... }:
{
  den.aspects.system.fstrim.nixos.services.fstrim.enable = true;
}
