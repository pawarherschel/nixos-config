# system.boot.kernel.zen — Linux Zen kernel.
{ den, ... }:
{
  den.aspects.system.boot.kernel.zen.nixos =
    { pkgs, ... }:
    {
      boot.kernelPackages = pkgs.linuxPackages_zen;
    };
}
