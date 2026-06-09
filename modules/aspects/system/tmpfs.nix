# system.tmpfs — tmpfs for /tmp.
{ lib, ... }:
{
  den.aspects.system.tmpfs.nixos = {
    boot.tmp = {
      useTmpfs = true;
      tmpfsSize = lib.mkDefault "80%";
      cleanOnBoot = true;
    };
  };
}
