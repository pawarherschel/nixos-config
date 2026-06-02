# system.zram — zram swap.
{ lib, ... }:
{
  den.aspects.system.zram.nixos = {
    zramSwap.enable = true;
    zramSwap.algorithm = lib.mkDefault "zstd";
  };
}
