# kimi-code — AI-powered code assistant CLI
{ inputs, ... }:
{
  flake-file.inputs = {
    kimi-code = {
      url = "github:MoonshotAI/kimi-code";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.programs.kimi-code = {
    nixos =
      { pkgs, ... }:
      let
        kimiPkg = inputs.kimi-code.packages.${pkgs.stdenv.hostPlatform.system}.default;
      in
      {
        environment.systemPackages = [
          kimiPkg
        ];
      };
  };
}
