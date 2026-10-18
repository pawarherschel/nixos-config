# juju integrates Jujutsu and Git; its supported Jujutsu minimum is 0.42.
{ ... }:
{
  den.aspects.programs.helix.homeManager =
    { lib, pkgs, ... }:
    {
      assertions = [
        {
          assertion = lib.versionAtLeast pkgs.jujutsu.version "0.42";
          message = "Helix juju requires Jujutsu >= 0.42.";
        }
      ];
      programs.nhx = {
        requiredPackages = [
          pkgs.git
          pkgs.jujutsu
        ];
        plugins.juju.enable = true;
      };
    };
}
