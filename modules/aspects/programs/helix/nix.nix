# helix.nix — Nix language + LSP config + system packages.
{ den, lib, ... }:
{
  den.aspects.programs.helix.nix = {
    includes = [ den.aspects.overlays.nil ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          deadnix
          nil
          nixd
          nixfmt
          statix
        ];
      };

    homeManager =
      { pkgs, lib, ... }:
      let
        nil = lib.getExe pkgs.nil;
        nixd = lib.getExe pkgs.nixd;
        nixfmt = lib.getExe pkgs.nixfmt;
      in
      {
        programs.helix.languages = {
          language-server.nil.command = nil;
          language-server.nixd.command = nixd;

          language = [
            {
              name = "nix";
              file-types = [ "nix" ];
              language-servers = [
                "nil"
                "nixd"
              ];
              formatter.command = nixfmt;
              auto-format = true;
            }
          ];
        };
      };
  };
}
