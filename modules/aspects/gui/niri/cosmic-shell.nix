# gui.niri.cosmic-shell — COSMIC shell components on niri.
# Launched via cosmic-session niri with cosmic-ext-alternative-startup.
{ inputs, den, ... }: {

  flake-file.inputs = {
    cosmic-manager = {
      url = "github:HeitorAugustoLN/cosmic-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.gui.niri.cosmic-shell = {
    includes = [ den.aspects.overlays.cosmic-ext-alternative-startup ];

    nixos =
      {
        pkgs,
        config,
        ...
      }:
      let
        ksakuraUid = toString config.users.users.ksakura.uid;

        start-cosmic-niri = pkgs.writeShellApplication {
          name = "start-cosmic-niri";
          runtimeInputs = with pkgs; [
            systemd
            dbus
            cosmic-session
            bash
            coreutils
          ];
          text = ''
            set -e

            if command -v systemctl >/dev/null; then
              for unit in $(systemctl --user --no-legend --state=failed --plain list-units | cut -f1 -d' '); do
                partof="$(systemctl --user show -p PartOf --value "$unit")"
                for target in cosmic-session.target graphical-session.target; do
                  if [ "$partof" = "$target" ]; then
                    systemctl --user reset-failed "$unit"
                    break
                  fi
                done
              done
            fi

            if [ "''${1:-}" != "--in-login-shell" ]; then
              exec bash -l -c "exec ''${0} --in-login-shell"
            fi

            export XDG_CURRENT_DESKTOP="''${XDG_CURRENT_DESKTOP:=niri}"
            export XDG_SESSION_TYPE="''${XDG_SESSION_TYPE:=wayland}"
            export XCURSOR_THEME="''${XCURSOR_THEME:=Cosmic}"
            export _JAVA_AWT_WM_NONREPARENTING=1
            export GDK_BACKEND=wayland,x11
            export MOZ_ENABLE_WAYLAND=1
            export QT_QPA_PLATFORM="wayland;xcb"
            export QT_AUTO_SCREEN_SCALE_FACTOR=1
            export QT_ENABLE_HIGHDPI_SCALING=1

            if command -v systemctl >/dev/null; then
              systemctl --user import-environment XDG_SESSION_TYPE XDG_CURRENT_DESKTOP
            fi

            if [[ -z "''${DBUS_SESSION_BUS_ADDRESS}" ]]; then
              exec dbus-run-session -- cosmic-session niri
            else
              exec cosmic-session niri
            fi
          '';
        };

        session-desktop = pkgs.writeTextFile {
          name = "cosmic-on-niri";
          destination = "/share/wayland-sessions/cosmic-on-niri.desktop";
          text = ''
            [Desktop Entry]
            Name=COSMIC-on-niri
            Comment=COSMIC desktop shell on niri compositor
            Type=Application
            DesktopNames=niri
            Exec=${start-cosmic-niri}/bin/start-cosmic-niri
          '';
        };

      in
      {
        services.displayManager = {
          sessionPackages = [
            (session-desktop.overrideAttrs (_: {
              passthru.providedSessions = [ "cosmic-on-niri" ];
            }))
          ];
          cosmic-greeter.enable = true;
        };

        system.activationScripts.cosmic-greeter-config = ''
          GREETER_DIR="/var/lib/cosmic-greeter/.config/cosmic/com.system76.CosmicGreeter/v1"
          mkdir -p "$GREETER_DIR"
          echo 'Some(${ksakuraUid})' > "$GREETER_DIR/last_user"
          cat > "$GREETER_DIR/users" << 'EOF'
          {
              ${ksakuraUid}: (
                  uid: ${ksakuraUid},
                  last_session: Some("COSMIC-on-niri"),
              ),
          }
          EOF
          chown -R cosmic-greeter:cosmic-greeter "$GREETER_DIR"
          chmod 0600 "$GREETER_DIR/last_user" "$GREETER_DIR/users"
        '';

        environment.systemPackages = with pkgs; [
          cosmic-ext-alternative-startup
          cosmic-session
          cosmic-panel
          cosmic-applets
          cosmic-applibrary
          cosmic-launcher
          cosmic-bg
          cosmic-notifications
          cosmic-osd
          cosmic-settings-daemon
          cosmic-settings
          cosmic-greeter
          xwayland-satellite
          cosmic-term
          pop-launcher
        ];

        xdg.portal = {
          extraPortals = with pkgs; [
            xdg-desktop-portal-gtk
            xdg-desktop-portal-cosmic
          ];
          config.niri = {
            default = [ "gtk" ];
            "org.freedesktop.impl.portal.Access" = [ "gtk" ];
            "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
            "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          };
          configPackages = [ pkgs.xdg-desktop-portal-cosmic ];
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

        programs.niri.settings."spawn-at-startup" = [
          { argv = [ (lib.getExe pkgs.cosmic-ext-alternative-startup) ]; }
          {
            argv = [
              (lib.getExe pkgs.xwayland-satellite)
              ":13"
            ];
          }
        ];
      };
  };
}
