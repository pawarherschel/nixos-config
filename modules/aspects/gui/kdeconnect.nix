# gui.kdeconnect — KDE Connect integration. DE picks the package.
_:
{
  den.aspects.gui.kdeconnect.nixos =
    _:
    {
      programs.kdeconnect = {
        enable = true;
      };
    };
}
