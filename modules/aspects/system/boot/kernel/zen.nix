# system.boot.kernel.zen — Linux Zen kernel.
_: {
  den.aspects.system.boot.kernel.zen.nixos =
    { pkgs, ... }:
    {
      boot.kernelPackages = pkgs.linuxPackages_zen;
    };
}
