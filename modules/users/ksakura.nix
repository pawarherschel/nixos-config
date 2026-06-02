# ksakura — primary user.
{ den, ... }:
{
  den.aspects.ksakura.provides.to-hosts.nixos =
    { pkgs, ... }:
    {
      users.users.ksakura = {
        description = "Kathryn Sakura";
        extraGroups = [
          "networkmanager"
          "wheel"
          "audio"
          "sound"
          "video"
          "libvirtd"
        ];
        shell = pkgs.nushell;
      };
    };
}
