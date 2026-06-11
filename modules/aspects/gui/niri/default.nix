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

    provides.to-users = _: {
      homeManager = _: {
        programs.niri = {
          settings = {
            prefer-no-csd = true;

            environment.XCURSOR_THEME = "Cosmic";

            input.keyboard.xkb.layout = "us";

            "spawn-at-startup" = [
              { argv = [ "cosmic-ext-alternative-startup" ]; }
              { argv = [ "xwayland-satellite" ":13" ]; }
            ];

            binds = {
              "Mod+Return".action.close-window = { };
              "Mod+Q".action.spawn = "kitty";
              "Mod+T".action.spawn = "kitty";
              "Mod+D".action.spawn = "cosmic-launcher";
              "Mod+Shift+D".action.spawn = "cosmic-app-library";
              "Mod+Alt+L".action.spawn = "cosmic-greeter";
              "Mod+F".action.maximize-column = { };
              "Mod+Shift+F".action.fullscreen-window = { };
              "Mod+V".action.toggle-window-floating = { };
            };
          };
        };
      };
    };
  };
}
