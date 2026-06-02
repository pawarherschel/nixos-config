# nushell — shell with default configs. Prompt customized by starship.
{ den, lib, ... }:
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

    homeManager = {
      programs.nushell = {
        enable = true;
        configFile.text = builtins.readFile defaults.config;
        envFile.text = builtins.readFile defaults.env;
      };
    };
  };
}
