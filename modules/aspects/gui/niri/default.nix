# gui.niri — niri scrollable-tiling compositor.
# Includes cosmic-shell for the COSMIC shell integration.
{ inputs, den, ... }:
{
  flake-file.inputs.niri.url = "github:sodiboo/niri-flake";

  den.aspects.gui.niri = {
    includes = [
      den.aspects.gui
      den.aspects.gui.wayland
      den.aspects.gui.niri.cosmic-shell
    ];

    nixos =
      { ... }:
      {
        imports = [ inputs.niri.nixosModules.niri ];

        programs.niri.enable = true;
      };

    homeManager =
      { inputs, ... }:
      {
        imports = [
          inputs.niri.homeModules.niri
          inputs.niri.homeModules.stylix
        ];

        programs.niri.settings = {
          prefer-no-csd = true;

          environment.XCURSOR_THEME = "Cosmic";

          input.keyboard.xkb.layout = "us";

          binds = {
            "Mod+T".spawn = "cosmic-term";
            "Mod+D".spawn = "cosmic-launcher";
            "Mod+Shift+D".spawn = "cosmic-app-library";
            "Mod+Alt+L".spawn = "cosmic-greeter";
          };
        };
      };
  };
}
