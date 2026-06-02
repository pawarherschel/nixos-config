# gui.social — Discord and Signal.
_: {
  den.aspects.gui.social.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        discord
        signal-desktop
      ];
    };
}
