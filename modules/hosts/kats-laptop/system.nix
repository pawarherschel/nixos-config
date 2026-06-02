# kats-laptop.system — mechanical host config.
{
  den,
  lib,
  config,
  ...
}:
{
  den.aspects.kats-laptop.system = {
    includes = [
      den.aspects.system.boot.kernel.zen
      den.aspects.system.boot.limine
      # den.aspects.system.boot.plymouth
      den.aspects.system.fstrim
      den.aspects.system.no-auto-upgrade
      den.aspects.system.ssh
      den.aspects.system.tmpfs
      den.aspects.system.zram
    ];

    nixos = {
      # EFI
      boot.loader.efi.canTouchEfiVariables = true;

      hardware.enableRedistributableFirmware = true;

      # Kernel tuning
      boot.extraModprobeConfig = "options kvm_intel nested=1";

      # Nix settings
      nix.settings.system-features = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
        "gccarch-skylake"
      ];
      nix.settings.cores = 4;
      nix.settings.max-jobs = 4;

      system.autoUpgrade.allowReboot = false;

      # VM variant for testing
      virtualisation.vmVariant = {
        hardware.cpu.intel.updateMicrocode = lib.mkForce true;
        users.users.ksakura.initialPassword = "vm";
        services.getty.autologinUser = "ksakura";
        services.greetd.settings.initial_session = lib.mkForce {
          user = "ksakura";
        };
      };
    };
  };
}
