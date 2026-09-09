# jujutsu — VCS, replaces git.
_: {
  den.aspects.programs.jujutsu = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          pkgs.jujutsu
          pkgs.jj-starship
          (pkgs.blazingjj.overrideAttrs (_: {
            doCheck = false;
          }))
        ];
      };

    provides.ksakura.homeManager = {
      programs.starship.settings.custom.jj = {
        when = "jj-starship detect";
        shell = [ "jj-starship" ];
        format = "$output ";
      };

      programs.jujutsu = {
        enable = true;
        settings = {
          user = {
            email = "pawarherschel@gmail.com";
            name = "Herschel Pawar";
          };
          # jj tug — move the closest ancestor bookmark to @- (the change under an empty @).
          # https://shaddy.dev/notes/jj-tug/
          # Caveats:
          # - moves ALL bookmarks on that ancestor change, not just one
          # - avoid right after a merge commit (the parent is ambiguous)
          aliases.tug = [
            "bookmark"
            "move"
            "--from"
            "heads(::@- & bookmarks())"
            "--to"
            "@-"
          ];
          aliases.fdiff = [
            "util"
            "exec"
            "--"
            "bash"
            "-c"
            "target=\${1:-@}; jj diff --from \"fork_point(trunk()|$target)\" --to \"$target\""
            "--"
          ];
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
