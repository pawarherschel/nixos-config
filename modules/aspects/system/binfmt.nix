# system.binfmt — QEMU binfmt emulation for multi-arch builds.
_: {
  den.aspects.system.binfmt.nixos =
    { pkgs, ... }:
    {
      boot.binfmt.emulatedSystems = builtins.filter (s: s != pkgs.stdenv.hostPlatform.system) [
        "aarch64-linux"
        "x86_64-linux"
      ];
    };
}
