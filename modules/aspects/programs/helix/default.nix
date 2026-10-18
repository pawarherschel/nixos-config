# helix — editor with per-language configs.
{ den, inputs, ... }:
{
  flake-file.inputs.nhx = {
    url = "github:Ra77a3l3-jar/nhx";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.programs.helix = {
    homeManager = {
      imports = [ inputs.nhx.homeManagerModules.default ];
      home.sessionVariables.EDITOR = "hx";
      home.sessionVariables.VISUAL = "hx";
      programs.nhx = {
        enable = true;
        steel = {
          enable = true;
          lsp.enable = false;
        };
      };
    };

    development = {
      includes = [
        den.aspects.programs.helix
        den.aspects.programs.helix.json
        den.aspects.programs.helix.javascript
        # den.aspects.programs.helix.markdown
        den.aspects.programs.helix.nix
        den.aspects.programs.helix.toml
        den.aspects.programs.helix.typst
      ];

      homeManager = _: {
        programs.nhx = {
          settings = {
            # theme = "dracula";
            keys.normal.esc = [
              "collapse_selection"
              "keep_primary_selection"
            ];
            editor = {
              line-number = "relative";
              cursor-shape = {
                insert = "bar";
                normal = "block";
                select = "underline";
              };
              lsp.display-inlay-hints = true;
              whitespace.render = {
                space = "all";
                nbsp = "all";
                tab = "all";
                newline = "none";
                tabpad = "all";
              };
              indent-guides = {
                render = true;
                character = "╎";
                skip-levels = 1;
              };
            };
          };
        };
      };
    };
  };
}
