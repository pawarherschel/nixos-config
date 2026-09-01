# programs.social — Discord and Signal.
_: {
  den.aspects.programs.social.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        discord
        signal-desktop
        slack
      ];
    };
}
