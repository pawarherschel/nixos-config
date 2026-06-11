# kat — unprivileged SSH user. No home-manager.
_: {
  den.aspects.kat.provides.to-hosts.nixos.users.users.kat = {
    isNormalUser = true;
    description = "_kat";
    uid = 1000;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}
