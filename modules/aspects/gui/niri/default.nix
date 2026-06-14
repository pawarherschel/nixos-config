# gui.niri — niri scrollable-tiling compositor.
# Includes cosmic-shell for the COSMIC shell integration.
{ inputs, den, ... }:
{
  flake-file.inputs = {
    niri.url = "github:sodiboo/niri-flake";
    cosmic-manager = {
      url = "github:HeitorAugustoLN/cosmic-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

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
      homeManager = { pkgs, lib, ... }: {
        imports = [ inputs.cosmic-manager.homeManagerModules.cosmic-manager ];

        wayland.desktopManager.cosmic.enable = true;

        programs.niri = {
          settings = {
            prefer-no-csd = true;

            environment.XCURSOR_THEME = "Cosmic";

            input.keyboard.xkb.layout = "us";

            "spawn-at-startup" = [
              { argv = [ "cosmic-ext-alternative-startup" ]; }
              {
                argv = [
                  (lib.getExe pkgs.xwayland-satellite)
                  ":13"
                ];
              }
            ];

            binds = {
              "Mod+Backspace".action.close-window = { };
              "Mod+Q".action.spawn = lib.getExe pkgs.kitty;
              "Mod+D".action.spawn = lib.getExe pkgs.cosmic-launcher;
              "Mod+Shift+D".action.spawn = lib.getExe pkgs.cosmic-applibrary;
              "Mod+Alt+L".action.spawn = lib.getExe pkgs.cosmic-greeter;
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
