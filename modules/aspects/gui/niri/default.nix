# gui.niri — niri scrollable-tiling compositor.
# Includes cosmic-shell for the COSMIC shell integration.
{ inputs, den, ... }:
{
  flake-file.inputs = {
    niri.url = "github:sodiboo/niri-flake";
  };

  den.aspects.gui.niri = {
    includes = [
      den.aspects.gui
      den.aspects.gui.wayland
      den.aspects.gui.niri.cosmic-shell
      den.aspects.gui.niri.config
    ];

    nixos =
      { config, pkgs, ... }:
      {
        imports = [ inputs.niri.nixosModules.niri ];

        programs.niri.enable = true;
        programs.niri.package = pkgs.niri;

        home-manager.extraSpecialArgs = {
          stylixImage = config.stylix.image;
        };
      };

    provides.ksakura.homeManager =
      {
        ...
      }:
      {
        stylix.targets.niri.enable = true;
      };
  };
}
