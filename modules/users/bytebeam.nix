# bytebeam — primary user on kats-macbook.
{ den, inputs, ... }:
{
  den.aspects.bytebeam = {
    includes = [
      den.aspects.cli
      den.aspects.programs.helix.development
      den.aspects.programs.omp
    ];

    homeManager = { config, pkgs, ... }: {
      imports = [ inputs.agenix.homeManagerModules.age ];
      wrappers.git.settings.user = {
        name = "Herschel Pawar";
        email = "pawarherschel@gmail.com";
      };
      wrappers.jujutsu.settings.user = config.wrappers.git.settings.user;

      age.identityPaths = [
        "${config.home.homeDirectory}/.config/age/identity.txt"
        "${config.home.homeDirectory}/.ssh/id_ed25519"
      ];
      age.secrets.gitKey = {
        file = ../aspects/programs/git/gitKey.age;
        path = "${config.home.homeDirectory}/.ssh/git-key";
        mode = "0400";
      };
      programs.ssh.enable = true;
      programs.ssh.enableDefaultConfig = false;
      programs.ssh.settings = {
        "github.com".IdentityFile = config.age.secrets.gitKey.path;
        "tangled.org".IdentityFile = config.age.secrets.gitKey.path;
        "*" = {
          ForwardAgent = false;
          AddKeysToAgent = "no";
          Compression = false;
          ServerAliveInterval = 0;
          ServerAliveCountMax = 3;
          HashKnownHosts = false;
          UserKnownHostsFile = "~/.ssh/known_hosts";
          ControlMaster = "no";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "no";
        };
      };
      home.stateVersion = "26.05";
      home.packages = [ pkgs.zed-editor ];
    };

    provides.to-hosts.darwin = { config, ... }: {
      age.rekey.masterIdentities = config.home-manager.users.bytebeam.age.identityPaths;
      users.users.bytebeam = {
        uid = 501;
        home = "/Users/bytebeam";
      };
    };
  };
}
