# helium — browser. Includes overlay, system package, desktop entry, mime.
{ den, ... }:
{
  den.aspects.programs.helium = {
    includes = [ den.aspects.overlays.helium ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.helium ];
      };

    provides.ksakura.homeManager = _: {
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = "helium.desktop";
          "x-scheme-handler/http" = "helium.desktop";
          "x-scheme-handler/https" = "helium.desktop";
          "x-scheme-handler/about" = "helium.desktop";
          "x-scheme-handler/unknown" = "helium.desktop";
          "text/plain" = "helix.desktop";
        };
      };
    };
  };
}
