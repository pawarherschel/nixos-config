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
      programs.ssh.matchBlocks = {
        github = {
          host = "github.com";
          identityFile = config.age.secrets.gitKey.path;
        };
        tangled = {
          host = "tangled.org";
          identityFile = config.age.secrets.gitKey.path;
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
