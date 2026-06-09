# opencode — AI coding agent with HM integration + web access.
{ den, ... }:
{
  den.aspects.programs.opencode = {
    includes = [
      den.aspects.overlays.opencode
    ];

    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.opencode ];
    };

    homeManager = { ... }: {
      programs.opencode = {
        enable = true;
        settings = {
          lsp = true;
          shell = "nu";
          snapshot = false;
          compaction.prune = true;
          plugin = [ "@tarquinen/opencode-dcp@latest" ];
        };
        web.enable = true;
      };
    };
  };
}
