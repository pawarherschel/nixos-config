# cli.nix-helpers — nh and nix-output-monitor.
{ den, ... }:
{
  den.aspects.cli.nix-helpers.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        nh
        nix-output-monitor
      ];
    };
}
