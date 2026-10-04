# gh — GitHub CLI.
_: {
  den.aspects.programs.gh = {
    homeManager = {
      programs.gh = {
        enable = true;
        settings = {
          editor = "hx";
          version = 1;
          git_protocol = "https";
          prompt = "enable";
        };
      };
    };
  };
}
