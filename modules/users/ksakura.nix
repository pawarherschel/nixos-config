# ksakura — primary user.
_: {
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

      age.rekey.masterIdentities = [
        "/home/ksakura/.config/agenix/identity.txt"
      ];
    };
}
