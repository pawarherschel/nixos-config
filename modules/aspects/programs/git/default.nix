# git — portable configuration; identities and secrets belong to users.
{ inputs, ... }:
{
  den.aspects.programs.git.homeManager = { config, lib, ... }: {
    imports = [ inputs.wrappers.homeModules.git ];
    wrappers.git.enable = true;
    # gh contributes these without enabling Home Manager's Git config owner.
    wrappers.git.settings.credential = lib.mkIf (
      config.programs.gh.enable && config.programs.gh.gitCredentialHelper.enable
    ) config.programs.git.settings.credential;
  };
}
