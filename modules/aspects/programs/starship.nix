# starship — prompt with jj integration.
{ den, ... }:
{
  den.aspects.programs.starship = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.starship ];
      };

    homeManager = {
      programs.starship = {
        enable = true;
        settings = {
          # username.show_always = true;
          custom.jj = {
            ignore_timeout = true;
            description = "current jj status";
            symbol = "";
            when = true;
            command = ''
              jj root > /dev/null && jj log --revisions @ --no-graph --ignore-working-copy --color always --limit 1 --template '
                separate(" ",
                  "🥋",
                  change_id.shortest(4),
                  bookmarks,
                  "|",
                  concat(
                    if(conflict, "💥"),
                    if(divergent, "🚧"),
                    if(hidden, "👻"),
                    if(immutable, "🔒"),
                  ),
                  raw_escape_sequence("\x1b[1;32m") ++ if(empty, "(empty)"),
                  raw_escape_sequence("\x1b[1;32m") ++ if(description.first_line().len() == 0,
                    "(no description set)",
                    if(description.first_line().substr(0, 29) == description.first_line(),
                      description.first_line(),
                      description.first_line().substr(0, 29) ++ "…",
                    )
                  ) ++ raw_escape_sequence("\x1b[0m"),
                )
              '
            '';
          };
          git_state.disabled = true;
          git_commit.disabled = true;
          git_metrics.disabled = true;
          git_branch.disabled = true;
          custom.git_branch = {
            when = true;
            command = "jj root >/dev/null 2>&1 || starship module git_branch";
            description = "Only show git_branch if we're not in a jj repo";
          };
        };
      };
    };
  };
}
