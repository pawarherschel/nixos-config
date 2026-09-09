# cli — standard util replacements. Includes all programs.
{ den, ... }:
{
  den.aspects.cli = {
    includes = [
      den.aspects.cli.nix-helpers
      den.aspects.cli.devenv
      den.aspects.programs.atuin
      den.aspects.programs.bat
      den.aspects.programs.carapace
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
      { pkgs, lib, ... }:
      {
        environment.systemPackages = with pkgs; [
          difftastic
          fzf
          # kdiff3
          # mergiraf
          ripgrep
          waypipe
          zellij
          libnotify
        ];

        programs.bash.interactiveShellInit = ''
          # TODO: jj alias completion broken — see jujutsu.nix comment.
          # _jj_alias_wrap was tried but `jj util completion bash` doesn't include
          # aliases. The wrapper handles fdiff (bookmark completion) and tug (no-args)
          # but conflicts with jj's own _jj function in some cases.
          #
          eval "$(${lib.getExe pkgs.fzf} --bash)"
          source "$(${lib.getExe pkgs.jujutsu} util completion bash)"
          _jj_alias_wrap() {
            case "''${COMP_WORDS[1]}" in
              fdiff)
                COMPREPLY=($(compgen -W "$(${lib.getExe pkgs.jujutsu} bookmark list --template 'name ++ "\n"' 2>/dev/null) @ @-" -- "''${COMP_WORDS[COMP_CWORD]}"))
                ;;
              tug)
                COMPREPLY=()
                ;;
              *)
                _jj "$@"
                ;;
            esac
          }
          complete -F _jj_alias_wrap jj
        '';
      };
  };
}
