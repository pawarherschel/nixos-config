# ksakura — primary user.
{ den, ... }:
{
  den.aspects.ksakura = {
    includes = [ den.aspects.cli ];

    provides.to-hosts.nixos =
      { pkgs, ... }:
      {
        users.users.ksakura = {
          description = "Kathryn Sakura";
          uid = 1001;
          extraGroups = [
            "networkmanager"
            "wheel"
            "audio"
            "sound"
            "video"
            "libvirtd"
            "input"
          ];
          shell = pkgs.nushell;
        };

        age.rekey.masterIdentities = [
          "/home/ksakura/.config/agenix/identity.txt"
        ];
      };
  };
}
