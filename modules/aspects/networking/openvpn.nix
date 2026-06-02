# networking.openvpn — OpenVPN client + NetworkManager plugin.
_: {
  den.aspects.networking.openvpn.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        networkmanager-openvpn
        openvpn
      ];
    };
}
