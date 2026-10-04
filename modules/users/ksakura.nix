# ksakura — primary user.
{ den, ... }:
{
  den.aspects.ksakura = {
    includes = [
      den.aspects.cli
      den.aspects.programs.helix.development
      den.aspects.programs.omp
    ];

    homeManager = { config, ... }: {
      wrappers.git.settings.user = {
        email = "pawarherschel@gmail.com";
        name = "Herschel Pawar";
      };
      wrappers.jujutsu.settings.user = config.wrappers.git.settings.user;
    };

    provides.to-hosts.nixos =
      { config, pkgs, ... }:
      {
        age.secrets.gitKey = {
          rekeyFile = ../aspects/programs/git/gitKey.age;
          owner = "ksakura";
          mode = "0400";
        };

        programs.ssh.extraConfig = ''
          Match host github.com
            IdentityFile ${config.age.secrets.gitKey.path}
          Match host tangled.org
            IdentityFile ${config.age.secrets.gitKey.path}
        '';

        users.users.ksakura = {
          description = "Kathryn Sakura";
          uid = 1001;
          extraGroups = [
            "networkmanager"
            "wheel"
            "audio"
            "sound"
            "video"
            "libvirtd"
            "input"
          ];
          shell = pkgs.nushell;
        };

        age.rekey.masterIdentities = [
          "/home/ksakura/.config/agenix/identity.txt"
        ];
      };
  };
}
