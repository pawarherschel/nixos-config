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
      den.aspects.gui.niri.default-config
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
        pkgs,
        lib,
        stylixImage,
        ...
      }:
      {
        imports = [ inputs.cosmic-manager.homeManagerModules.cosmic-manager ];

        wayland.desktopManager.cosmic = {
          enable = true;
          wallpapers = [
            {
              output = "all";
              source = {
                __type = "enum";
                variant = "Path";
                value = [ stylixImage ];
              };
              filter_by_theme = true;
              filter_method = {
                __type = "enum";
                variant = "Lanczos";
              };
              scaling_mode = {
                __type = "enum";
                variant = "Fit";
                value = [
                  {
                    __type = "tuple";
                    value = [
                      0.5
                      1.0
                      {
                        __type = "raw";
                        value = "0.345354352";
                      }
                    ];
                  }
                ];
              };
              sampling_method = {
                __type = "enum";
                variant = "Alphanumeric";
              };
              rotation_frequency = 600;
            }
          ];
          # panels = [
          #   {
          #     anchor = {
          #       __type = "enum";
          #       variant = "Top";
          #     };
          #     anchor_gap = false;
          #     autohide = {
          #       __type = "optional";
          #       value = null;
          #     };
          #     background = {
          #       __type = "enum";
          #       variant = "Dark";
          #     };
          #     expand_to_edges = true;
          #     name = "Panel";
          #     margin = 0;
          #     opacity = 1.0;
          #     output = {
          #       __type = "enum";
          #       variant = "All";
          #     };
          #     plugins_center = {
          #       __type = "optional";
          #       value = [ "com.system76.CosmicAppletTime" ];
          #     };
          #     plugins_wings = {
          #       __type = "optional";
          #       value = {
          #         __type = "tuple";
          #         value = [
          #           [ "com.system76.CosmicPanelAppButton" ]
          #           [
          #             "com.system76.CosmicAppletInputSources"
          #             "com.system76.CosmicAppletStatusArea"
          #             "com.system76.CosmicAppletA11y"
          #             "com.system76.CosmicAppletAudio"
          #             "com.system76.CosmicAppletBluetooth"
          #             "com.system76.CosmicAppletNetwork"
          #             "com.system76.CosmicAppletBattery"
          #             "com.system76.CosmicAppletNotifications"
          #             "com.system76.CosmicAppletPower"
          #           ]
          #         ];
          #       };
          #     };
          #     size = {
          #       __type = "enum";
          #       variant = "XS";
          #     };
          #   }
          #   {
          #     anchor = {
          #       __type = "enum";
          #       variant = "Bottom";
          #     };
          #     anchor_gap = true;
          #     autohide = {
          #       __type = "optional";
          #       value = {
          #         handle_size = 4;
          #         transition_time = 200;
          #         wait_time = 1000;
          #       };
          #     };
          #     background = {
          #       __type = "enum";
          #       variant = "Dark";
          #     };
          #     expand_to_edges = true;
          #     name = "Dock";
          #     margin = 4;
          #     opacity = 1.0;
          #     output = {
          #       __type = "enum";
          #       variant = "All";
          #     };
          #     plugins_center = {
          #       __type = "optional";
          #       value = [
          #         "com.system76.CosmicPanelLauncherButton"
          #         "com.system76.CosmicPanelAppButton"
          #       ];
          #     };
          #     plugins_wings = {
          #       __type = "optional";
          #       value = {
          #         __type = "tuple";
          #         value = [
          #           [ ]
          #           [ ]
          #         ];
          #       };
          #     };
          #     size = {
          #       __type = "enum";
          #       variant = "L";
          #     };
          #   }
          # ];
        };

        programs.niri = {
          settings = {
            prefer-no-csd = true;

            environment.XCURSOR_THEME = "Cosmic";

            input.keyboard.xkb.layout = "us";

            "spawn-at-startup" = [
              { argv = [ (lib.getExe pkgs.cosmic-ext-alternative-startup) ]; }
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
              "Mod+F".action.maximize-column = { };
              "Mod+Shift+F".action.fullscreen-window = { };
              "Mod+V".action.toggle-window-floating = { };
              "Mod+Shift+Slash".action.show-hotkey-overlay = { };
              "Mod+T" = null;
              "Mod+Alt+L" = null;
            };
          };
        };
      };
  };
}
