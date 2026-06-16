# gui.kdeconnect — KDE Connect integration.
_: {
  den.aspects.gui.kdeconnect = {
    nixos = _: {
      programs.kdeconnect.enable = true;
    };

    provides.ksakura.homeManager = {
      services.kdeconnect = {
        enable = true;
        indicator = true;
      };
    };
  };
}
