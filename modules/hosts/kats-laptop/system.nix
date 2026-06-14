# kats-laptop.system — mechanical host config.
{
  den,
  lib,
  ...
}:
{
  den.aspects.kats-laptop.system = {
    includes = [
      den.aspects.system.boot.kernel.zen
      den.aspects.system.boot.limine
      den.aspects.system.fstrim
      den.aspects.system.no-auto-upgrade
      den.aspects.system.ssh
      den.aspects.system.tmpfs
      den.aspects.system.zram
    ];

    nixos = { pkgs, ... }: {
      # EFI
      boot.loader.efi.canTouchEfiVariables = true;

      hardware.enableRedistributableFirmware = true;

      # Bluetooth
      hardware.bluetooth.enable = true;
      hardware.bluetooth.powerOnBoot = true;

      # Kernel tuning
      boot.extraModprobeConfig = "options kvm_intel nested=1";

      # Nix settings
      nix.settings = {
        system-features = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
          "gccarch-skylake"
        ];
        cores = 4;
        max-jobs = 4;
        extra-platforms = [ "aarch64-linux" ];
      };

      system.autoUpgrade.allowReboot = false;

      # VM variant for testing
      virtualisation.vmVariant = {
        hardware.cpu.intel.updateMicrocode = lib.mkForce true;
        users.users.ksakura.initialPassword = "vm";
        # services.greetd.settings.initial_session = lib.mkForce {
        #   user = "ksakura";
        #   command = "${pkgs.cosmic-session}/bin/cosmic-session niri";
        # };
      };
    };
  };
}
