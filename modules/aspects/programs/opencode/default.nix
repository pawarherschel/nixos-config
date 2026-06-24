# opencode — AI coding agent with HM integration, web access, RSS via Zenfeed.
{ den, ... }: {
  den.aspects.programs.opencode = {
    includes = [
      den.aspects.programs.opencode.zenfeed
    ];

    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.opencode ];
    };

    provides.ksakura.homeManager = { pkgs, lib, ... }: {
      programs.opencode = {
        enable = true;
        package =
          pkgs.runCommand "opencode-with-libstdc++"
            {
              nativeBuildInputs = [ pkgs.makeWrapper ];
              libPath = lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ];
            }
            ''
              mkdir -p $out/bin
              makeWrapper ${lib.getExe pkgs.opencode} $out/bin/opencode \
                --prefix LD_LIBRARY_PATH : $libPath
            '';
        settings = {
          lsp = true;
          shell = "${lib.getExe pkgs.nushell}";
          snapshot = false;
          compaction.prune = true;
          plugin = [ "opencode-mem" ];
          mcp = {
            zenfeed = {
              type = "remote";
              url = "http://127.0.0.1:1301/sse";
            };
            mdn = {
              type = "remote";
              url = "https://mcp.mdn.mozilla.net/";
            };
          };
        };
        context = builtins.readFile ./AGENTS.md;
      };
    };
  };
}
