# gui — graphical desktop environment (audio, portals).
# Pick a DE separately: den.aspects.gui.gnome or den.aspects.gui.cosmic etc.
{ den, ... }:
{
  den.aspects.gui = {
    includes = [
      den.aspects.gui.kdeconnect
      den.aspects.gui.pipewire
      den.aspects.gui.theme
      den.aspects.gui.xdg
    ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.jetbrains-toolbox ];
        security.polkit.enable = true;
      };
  };
}
