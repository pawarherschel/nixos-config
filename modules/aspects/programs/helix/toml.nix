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

    helixWrapper.languages = {
      language-server.tombi.command = "tombi";

      language = [
        {
          name = "toml";
          language-servers = [ "tombi" ];
          formatter.command = "taplo";
          formatter.args = [
            "format"
            "-"
          ];
          auto-format = true;
          roots = [ "." ];
        }
      ];
    };
  };
}
