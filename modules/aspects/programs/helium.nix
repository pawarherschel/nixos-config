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

    homeManager =
      { pkgs, ... }:
      {
        xdg.desktopEntries.helium = {
          name = "Helium";
          exec = "${pkgs.helium}/bin/helium %U";
          genericName = "Web Browser";
          comment = "Access the Internet";
          startupNotify = true;
          terminal = false;
          icon = "${pkgs.helium}/lib/helium-bin-${pkgs.helium.version}/product_logo_256.png";
          type = "Application";
          categories = [
            "Network"
            "WebBrowser"
          ];
          mimeType = [
            "application/pdf"
            "application/rdf+xml"
            "application/rss+xml"
            "application/xhtml+xml"
            "application/xhtml_xml"
            "application/xml"
            "image/gif"
            "image/jpeg"
            "image/png"
            "image/webp"
            "text/html"
            "text/xml"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
          ];
        };

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
