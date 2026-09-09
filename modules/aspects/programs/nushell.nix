# nushell — shell with default configs. Prompt customized by starship.
{ den, ... }:
let
  tag = "0.108.0";
  defaults = {
    config = builtins.fetchurl {
      url = "https://raw.githubusercontent.com/nushell/nushell/refs/tags/${tag}/crates/nu-utils/src/default_files/default_config.nu";
      sha256 = "sha256:018lbv7idyyj9wvc3bb4rlv2avi23i6fllzqq7agwj62pa3zf6s3";
    };
    env = builtins.fetchurl {
      url = "https://raw.githubusercontent.com/nushell/nushell/refs/tags/${tag}/crates/nu-utils/src/default_files/default_env.nu";
      sha256 = "sha256:09fpv8sa4dh4gjzy0z2cyfi734f0l3ckwp0k9fafg8cl7d1vkn40";
    };
  };
in
{
  den.aspects.programs.nushell = {
    includes = [ den.aspects.programs.starship ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.nushell ];
      };

    provides.ksakura.homeManager = { pkgs, lib, ... }: {
      programs.nushell = {
        enable = true;
        configFile.text = builtins.readFile defaults.config + ''

          # TODO: jj alias completion broken — see jujutsu.nix comment.
          # `use jj-completions.nu *` was tried but jj's generated completions don't
          # include aliases (tug, fdiff). The export extern declarations below were
          # added manually but don't integrate with nushell's span-based completion.
          #
          # jj native completions — handles built-in subcommands
          use ${
            pkgs.runCommand "jj-completions.nu" {
              buildInputs = [ pkgs.jujutsu ];
            } "${lib.getExe pkgs.jujutsu} util completion nushell > $out"
          } *

          # completions for custom aliases
          export extern "jj fdiff" [
            ...target: string  # Bookmark or revset to diff (default: @)
          ]
          export extern "jj tug" []

          # fzf integration
          mkdir ($nu.default-config-dir | path join "autoload")
          ${lib.getExe pkgs.fzf} --nushell | save -f ($nu.default-config-dir | path join "autoload" "_fzf_integration.nu")
        '';
        envFile.text = builtins.readFile defaults.env;
      };
    };
  };
}
