# helix — editor with per-language configs.
{ den, ... }:
{
  den.aspects.programs.helix = {
    nixos =
      { pkgs, ... }:
      {
        environment = {
          systemPackages = [ pkgs.helix ];
          variables.EDITOR = "hx";
          sessionVariables.EDITOR = "hx";
        };
      };

    provides.to-users = _: {
      includes = [
        den.aspects.programs.helix.json
        den.aspects.programs.helix.javascript
        # den.aspects.programs.helix.markdown
        den.aspects.programs.helix.nix
        den.aspects.programs.helix.toml
        den.aspects.programs.helix.typst
      ];

      homeManager = _: {
        home.sessionVariables.EDITOR = "hx";

        programs.helix = {
          enable = true;
          defaultEditor = true;
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
