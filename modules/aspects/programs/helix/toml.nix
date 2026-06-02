# helix.toml — TOML language + LSP config + system packages.
_: {
  den.aspects.programs.helix.toml = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          taplo
          tombi
        ];
      };

    homeManager =
      { pkgs, lib, ... }:
      let
        tombi = lib.getExe pkgs.tombi;
        taplo = lib.getExe pkgs.taplo;
      in
      {
        programs.helix.languages = {
          language-server.tombi.command = tombi;

          language = [
            {
              name = "toml";
              language-servers = [ "tombi" ];
              formatter = {
                command = taplo;
                args = [
                  "format"
                  "-"
                ];
              };
              auto-format = true;
              roots = [ "." ];
            }
          ];
        };
      };
  };
}
