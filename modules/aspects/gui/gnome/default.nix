# gui.gnome — GNOME desktop environment. Includes gui base automatically.
{ den, ... }:
{
  den.aspects.gui.gnome = {
    includes = [
      den.aspects.gui
      den.aspects.gui.gnome.astra-monitor
      den.aspects.gui.wayland
    ];

    nixos =
      { pkgs, ... }:
      {
        services.desktopManager.gnome.enable = true;
        services.gnome.core-apps.enable = false;
        services.gnome.core-developer-tools.enable = false;
        services.gnome.games.enable = false;
        environment.gnome.excludePackages = with pkgs; [
          gnome-tour
          gnome-user-docs
        ];
        programs.dconf.profiles.user.databases = [
          {
            settings = {
              "org/gnome/mutter".experimental-features = [ "xwayland-native-scaling" ];
            };
          }
        ];

        programs.kdeconnect.package = pkgs.gnomeExtensions.gsconnect;

        xdg.portal = {
          config.common.default = "gnome";
          extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
        };

        environment.systemPackages = with pkgs.gnomeExtensions; [
          app-name-indicator
          appindicator
          clipboard-indicator
          edit-desktop-files
          emoji-copy
          paperwm
          xwayland-indicator
        ];
      };
  };
}
