# helix.nix — Nix language + LSP config + system packages.
{ den, ... }:
{
  den.aspects.programs.helix.nix = {
    includes = [
      den.aspects.overlays.nil
      den.aspects.overlays.locker
    ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          deadnix
          locker
          nil
          nixd
          nixfmt
          statix
        ];
      };

    helixWrapper.languages = {
      language-server.nil.command = "nil";
      language-server.nixd.command = "nixd";

      language = [
        {
          name = "nix";
          file-types = [ "nix" ];
          language-servers = [
            "nil"
            "nixd"
          ];
          formatter.command = "nixfmt";
          auto-format = true;
        }
      ];
    };
  };
}
