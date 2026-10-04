# programs.social — shared messaging apps on Linux and Darwin.
_:
let
  common =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        discord
        signal-desktop
        slack
      ];
    };
in
{
  den.aspects.programs.social = {
    nixos = common;
    darwin = common;
  };
}
