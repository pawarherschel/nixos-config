# gui.wayland — Wayland utilities.
{ den, ... }:
{
  den.aspects.gui.wayland.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.wl-clipboard ];
    };
}
