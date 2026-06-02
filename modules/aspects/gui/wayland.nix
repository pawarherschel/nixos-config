# gui.wayland — Wayland utilities.
_: {
  den.aspects.gui.wayland.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.wl-clipboard ];
    };
}
