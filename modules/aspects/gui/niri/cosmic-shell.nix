# gui.niri.cosmic-shell — COSMIC shell components on niri.
# Launched via cosmic-session niri with cosmic-ext-alternative-startup.
_:
{
  den.aspects.gui.niri.cosmic-shell = {
    nixos =
      { pkgs, ... }:
      let
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

            if [ -n "''${SHELL:-}" ]; then
              if [ "''${1:-}" != "--in-login-shell" ]; then
                exec bash -c "exec -l ${"'"}''${SHELL}' -c ${"'"}''${0} --in-login-shell'"
              fi
            fi

            export XDG_CURRENT_DESKTOP="''${XDG_CURRENT_DESKTOP:=niri}"
            export XDG_SESSION_TYPE="''${XDG_SESSION_TYPE:=wayland}"
            export XCURSOR_THEME="''${XCURSOR_THEME:=Cosmic}"
            export _JAVA_AWT_WM_NONREPARENTING=1
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
            DesktopNames=niri-cosmic
            Exec=${start-cosmic-niri}/bin/start-cosmic-niri
          '';
        };

      in
      {
        services.displayManager.sessionPackages = [
          (session-desktop.overrideAttrs (_: {
            passthru.providedSessions = [ "cosmic-on-niri" ];
          }))
        ];

        services.displayManager.cosmic-greeter.enable = true;

        environment.systemPackages = with pkgs; [
          cosmic-ext-alternative-startup
          cosmic-session
          cosmic-panel
          cosmic-applibrary
          cosmic-launcher
          cosmic-bg
          cosmic-notifications
          cosmic-osd
          cosmic-settings-daemon
          cosmic-settings
          cosmic-idle
          cosmic-greeter
          xwayland-satellite
          cosmic-term
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
  };
}
