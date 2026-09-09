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
          #
          # TODO: shell completion for custom aliases is broken.
          # jj util completion bash/nushell does NOT include user-defined aliases.
          # The .doc table format was tried but jj 0.44.0 ignores it — `jj help tug`
          # says "unrecognized subcommand". What's needed: either jj gains alias
          # completion support, or we manually extend the generated completion scripts.
          aliases.tug = {
            definition = [
              "bookmark"
              "move"
              "--from"
              "heads(::@- & bookmarks())"
              "--to"
              "@-"
            ];
            doc = "Move closest ancestor bookmark to @-";
          };
          aliases.fdiff = {
            definition = [
              "util"
              "exec"
              "--"
              "bash"
              "-c"
              "target=\${1:-@}; jj diff --from \"fork_point(trunk()|$target)\" --to \"$target\""
              "--"
            ];
            doc = "Diff from fork point of trunk";
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
