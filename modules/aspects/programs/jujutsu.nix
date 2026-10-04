# jujutsu — VCS, replaces git.
{ inputs, ... }: {
  den.aspects.programs.jujutsu = {
    homeManager = { pkgs, ... }: {
      imports = [ inputs.wrappers.homeModules.jujutsu ];
      home.packages = [
        pkgs.jj-starship
      ];

      programs.starship.settings.custom.jj = {
        when = "jj-starship detect";
        shell = [ "jj-starship" ];
        format = "$output ";
      };

      wrappers.jujutsu = {
        enable = true;
        settings = {
          # jj tug — move the closest ancestor bookmark to @- (the change under an empty @).
          # https://shaddy.dev/notes/jj-tug/
          # Caveats:
          # - moves ALL bookmarks on that ancestor change, not just one
          # - avoid right after a merge commit (the parent is ambiguous)
          aliases = {
            tug = [
              "bookmark"
              "move"
              "--from"
              "heads(::@- & bookmarks())"
              "--to"
              "@-"
            ];
            fdiff = [
              "util"
              "exec"
              "--"
              "bash"
              "-c"
              "target=\${1:-@}; jj diff --from \"fork_point(trunk()|$target)\" --to \"$target\""
              "--"
            ];
            flog = [
              "util"
              "exec"
              "--"
              "bash"
              "-c"
              "target=\${1:-@}; jj log -r \"fork_point(trunk()|$target)..$target\""
              "--"
            ];
          };
          ui = {
            editor = "hx";
            paginate = "never";
            diff.tool = "difft";
            "diff-formatter" = [
              "difft"
              "--color=always"
              "$left"
              "$right"
            ];
            # "diff-editor" = "kdiff3";
            # "merge-editor" = "mergiraf";
          };
          "merge-tools" = {
            difft = {
              "diff-args" = [
                "--color=always"
                "$left"
                "$right"
              ];
            };
          };
        };
      };
    };
  };
}
