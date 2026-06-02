# networking.tailscale — VPN.
{ den, ... }:
{
  den.aspects.networking.tailscale = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.tailscale ];
        services.tailscale.enable = true;
      };
  };
}
