# gui.xdg — XDG autostart, terminal-exec, and DE-independent portals.
{ den, ... }:
{
  den.aspects.gui.xdg.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.xdg-utils ];

      xdg = {
        autostart.enable = true;
        terminal-exec = {
          enable = true;
          settings.default = [ "kitty.desktop" ];
        };
        portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-termfilechooser ];
        };
      };
    };
}
