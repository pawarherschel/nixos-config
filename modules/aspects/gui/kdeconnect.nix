# gui.kdeconnect — KDE Connect integration. DE picks the package.
{ lib, ... }:
{
  den.aspects.gui.kdeconnect.nixos =
    { pkgs, ... }:
    {
      programs.kdeconnect = {
        enable = true;
        package = lib.mkDefault pkgs.kdeconnect;
      };
    };
}
