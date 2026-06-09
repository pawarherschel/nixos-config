# gui.cosmic — COSMIC desktop environment. Includes gui base automatically.
{ den, ... }:
{
  den.aspects.gui.cosmic = {
    includes = [
      den.aspects.gui
      den.aspects.gui.wayland
    ];

    nixos = {
      services = {
        desktopManager.cosmic = {
          enable = true;
          xwayland.enable = true;
        };
        displayManager.cosmic-greeter.enable = true;
      };
    };
  };
}
