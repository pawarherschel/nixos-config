# opencode — AI coding agent with HM integration + web access.
_: {
  den.aspects.programs.opencode = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.opencode ];
    };

    provides.ksakura.homeManager = _: {
      programs.opencode = {
        enable = true;
        settings = {
          lsp = true;
          shell = "nu";
          snapshot = false;
          compaction.prune = true;
        };
        web.enable = true;
      };
    };
  };
}
