# kats-rpi.system — mechanical host config.
{ den, lib, ... }:
{
  den.aspects.kats-rpi.system = {
    includes = [
      den.aspects.system.ssh
      den.aspects.system.no-auto-upgrade
    ];

    nixos = {
      boot.loader.generic-extlinux-compatible.enable = true;
      boot.loader.timeout = 5;

      hardware.enableRedistributableFirmware = true;

      virtualisation.vmVariant = {
        users.users.ksakura.initialPassword = lib.mkForce "vm";
      };
    };
  };
}
