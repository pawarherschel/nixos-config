# networking.tailscale — VPN.
_:
let
  common = {
    services.tailscale.enable = true;
  };
in
{
  den.aspects.networking.tailscale = {
    nixos = common;
    darwin = common;
  };
}
