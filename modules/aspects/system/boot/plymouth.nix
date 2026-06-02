# system.boot.plymouth — boot splash.
{ lib, ... }:
{
  den.aspects.system.boot.plymouth.nixos =
    { pkgs, ... }:
    {
      boot.plymouth = {
        enable = true;
        themePackages = [ pkgs.plymouth-blahaj-theme ];
        theme = lib.mkForce "blahaj";
      };
    };
}
