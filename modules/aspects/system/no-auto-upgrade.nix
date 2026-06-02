# system.no-auto-upgrade — disables automatic NixOS upgrades.
{ den, ... }:
{
  den.aspects.system.no-auto-upgrade.nixos.system.autoUpgrade.enable = false;
}
