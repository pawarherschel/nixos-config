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
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        imports = [ inputs.niri.nixosModules.niri ];

        programs.niri.enable = true;
        programs.niri.package = pkgs.niri;

        systemd.user.services.niri-wayland-env = {
          description = "Propagate WAYLAND_DISPLAY to systemd user services";
          after = [ "niri.service" ];
          before = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${lib.getExe' pkgs.systemd "systemctl"} --user set-environment WAYLAND_DISPLAY=wayland-1";
          };
        };

        home-manager.extraSpecialArgs = {
          stylixImage = config.stylix.image;
        };
      };

    provides.ksakura.homeManager = _: {
      stylix.targets.niri.enable = true;
    };
  };
}
