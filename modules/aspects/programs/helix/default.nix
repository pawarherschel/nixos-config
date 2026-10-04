# helix — editor with per-language configs.
{ den, inputs, ... }:
{
  den.aspects.programs.helix = {
    homeManager = {
      imports = [ inputs.wrappers.homeModules.helix ];
      home.sessionVariables.EDITOR = "hx";
      home.sessionVariables.VISUAL = "hx";
      wrappers.helix.enable = true;
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
        wrappers.helix = {
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
