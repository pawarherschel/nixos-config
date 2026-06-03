# git
_: {
  den.aspects.programs.git = {
    nixos =
      { pkgs, config, ... }:
      {
        environment.systemPackages = [ pkgs.git ];

        age.secrets.gitKey = {
          rekeyFile = ./gitKey.age;
        };

        programs.ssh.extraConfig = ''
          Match host github.com
            IdentityFile ${config.age.secrets.gitKey.path}
          Match host tangled.org
            IdentityFile ${config.age.secrets.gitKey.path}
        '';
      };
  };
}
