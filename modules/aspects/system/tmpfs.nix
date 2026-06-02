# system.tmpfs — tmpfs for /tmp.
{ den, lib, ... }:
{
  den.aspects.system.tmpfs.nixos = {
    boot.tmp.useTmpfs = true;
    boot.tmp.tmpfsSize = lib.mkDefault "80%";
    boot.tmp.cleanOnBoot = true;
  };
}
