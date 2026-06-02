# gh — GitHub CLI.
_: {
  den.aspects.programs.gh = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.gh ];
      };

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
