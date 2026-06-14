# starship — prompt with jj integration.
_: {
  den.aspects.programs.starship = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.starship ];
      };

    provides.ksakura.homeManager = {
      programs.starship = {
        enable = true;
        settings = {
          # username.show_always = true;

          git_state.disabled = true;
          git_commit.disabled = true;
          git_metrics.disabled = true;
          git_branch.disabled = true;

        };
      };
    };
  };
}
