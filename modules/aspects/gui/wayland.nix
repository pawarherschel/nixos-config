# gui.wayland — Wayland utilities.
_: {
  den.aspects.gui.wayland.nixos =
    { pkgs, ... }:
    {
      environment = {
        systemPackages = [ pkgs.wl-clipboard ];
        sessionVariables.NIXOS_OZONE_WL = "1";
      };
    };
}
