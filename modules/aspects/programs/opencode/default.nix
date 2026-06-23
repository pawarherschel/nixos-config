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
          };
        };
        context = ''
          You have a local memory plugin enabled. For every user interaction, you must call the 'opencode-mem' search tool to pull relevant user preferences and historical project choices before formulating your answer.

          ## RSS feeds via Zenfeed
          When the user asks you to "catch up with RSS":
          1. Use Zenfeed MCP tools to query stored articles — search semantically by topic or filter by date/labels.
          2. For relevant articles, read full content and extract key insights.
          3. Store important facts in memory (opencode-mem) with tags: `rss`, `<topic>`.
          4. The Query API supports `summarize: true` for on-demand LLM summaries of search results.

          When discussing a topic, search RSS feeds via Zenfeed MCP first to check for relevant background knowledge stored in the vector database.

## Available scripting tools
This system does not have Python, Node.js, or other common scripting runtimes available. The only available scripting language is **Nushell** (`nu`). When you need to write small scripts for data processing, JSON parsing, API responses, or file manipulation, use Nushell — not Python, jq, node, or bash one-liners.
        '';
      };
    };
  };
}
