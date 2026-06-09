# kats-rpi.hardware — hardware config from nixos-generate-config.
_: {
  den.aspects.kats-rpi.hardware.nixos =
    { lib, ... }:
    {
      boot = {
        initrd.availableKernelModules = [
          "xhci_pci"
          "usbhid"
          "usb_storage"
        ];
        initrd.kernelModules = [ ];
        kernelModules = [ ];
        extraModulePackages = [ ];
      };

      fileSystems."/" = {
        device = "/dev/mmcblk0p2";
        fsType = "ext4";
        options = [ "noatime" ];
      };

      swapDevices = [ ];

      networking.useDHCP = lib.mkDefault true;

      nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
    };
}
