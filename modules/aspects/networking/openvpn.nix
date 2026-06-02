# networking.openvpn — OpenVPN client + NetworkManager plugin.
{ den, ... }:
{
  den.aspects.networking.openvpn.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        networkmanager-openvpn
        openvpn
      ];
    };
}
