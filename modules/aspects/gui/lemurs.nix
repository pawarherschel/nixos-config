# gui.lemurs — lemurs display manager
_: {
  den.aspects.gui.lemurs.nixos =
    { pkgs, ... }:
    {
      _ = throw "lemurs seems to be broken atm, it doesnt get into the DE after logging in (2026-06-02)";

      services.displayManager.lemurs = {
        enable = true;
        # settings = { };
      };
    };
}
