# jujutsu — VCS, replaces git.
_: {
  den.aspects.programs.jujutsu = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.jujutsu ];
      };

    homeManager = {
      programs.jujutsu = {
        enable = true;
        settings = {
          user = {
            email = "pawarherschel@gmail.com";
            name = "Herschel Pawar";
          };
          ui = {
            editor = "hx";
            paginate = "never";
          };
        };
      };
    };
  };
}
