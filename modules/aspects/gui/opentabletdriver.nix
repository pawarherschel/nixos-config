# gui.opentabletdriver — hardware + .desktop entry.
_: {
  den.aspects.gui.opentabletdriver = {
    nixos = {
      hardware.opentabletdriver.enable = true;
      hardware.uinput.enable = true;
      boot.kernelModules = [ "uinput" ];
    };

    provides.ksakura.homeManager.xdg.desktopEntries.OpenTabletDriver = {
      name = "OpenTabletDriver";
      genericName = "Tablet Driver";
      exec = "otd-gui";
      icon = "input-tablet";
      comment = "OpenTabletDriver Settings";
      categories = [
        "Settings"
        "HardwareSettings"
      ];
      type = "Application";
      terminal = false;
    };
  };
}
