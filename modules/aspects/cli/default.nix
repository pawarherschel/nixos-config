# cli — standard util replacements. Includes all programs.
{ den, ... }:
{
  den.aspects.cli = {
    includes = [
      den.aspects.cli.nix-helpers
      den.aspects.programs.atuin
      den.aspects.programs.bat
      den.aspects.programs.bottom
      den.aspects.programs.gh
      den.aspects.programs.git
      den.aspects.programs.helix
      den.aspects.programs.jujutsu
      den.aspects.programs.kitty
      den.aspects.programs.nushell
      den.aspects.programs.starship
      den.aspects.programs.syncthing
    ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          difftastic
          ripgrep
          zellij
          devenv
        ];
      };
  };
}
