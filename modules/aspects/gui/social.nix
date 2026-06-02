# gui.social — Discord and Signal.
{ den, ... }:
{
  den.aspects.gui.social.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        discord
        signal-desktop
      ];
    };
}
