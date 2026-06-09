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
