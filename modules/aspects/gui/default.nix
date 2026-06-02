# gui — graphical desktop environment (display manager, audio, portals).
# Pick a DE separately: den.aspects.gui.gnome or den.aspects.gui.cosmic
{ den, ... }:
{
  den.aspects.gui = {
    includes = [
      den.aspects.gui.greetd
      den.aspects.gui.kdeconnect
      den.aspects.gui.pipewire
      den.aspects.gui.theme
      den.aspects.gui.xdg
    ];

    nixos.security.polkit.enable = true;
  };
}
