# kat — unprivileged SSH user. No home-manager.
{ den, ... }:
{
  den.aspects.kat.provides.to-hosts.nixos.users.users.kat = {
    isNormalUser = true;
    description = "_kat";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}
