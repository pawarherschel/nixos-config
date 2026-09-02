# git
_: {
  den.aspects.programs.git = {
    nixos =
      { pkgs, config, ... }:
      {
        environment.systemPackages = [ pkgs.git ];

        age.secrets.gitKey = {
          rekeyFile = ./gitKey.age;
          owner = "ksakura";
          mode = "0400";
        };

        programs.ssh.extraConfig = ''
          Match host github.com
            IdentityFile ${config.age.secrets.gitKey.path}
          Match host tangled.org
            IdentityFile ${config.age.secrets.gitKey.path}
        '';
      };

    provides.ksakura.homeManager = {
      programs.git.enable = true;
      programs.git.settings = {
        user = {
          name = "Herschel Pawar";
          email = "pawarherschel@gmail.com";
        };
      };
    };
  };
}
