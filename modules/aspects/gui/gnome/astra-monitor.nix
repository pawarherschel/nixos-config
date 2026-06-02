# gui.gnome.astra-monitor — system monitor extension + deps.
_: {
  den.aspects.gui.gnome.astra-monitor.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        # runtime deps
        iotop
        pciutils
        wirelesstools
        # extension
        gnomeExtensions.astra-monitor
      ];
    };
}
