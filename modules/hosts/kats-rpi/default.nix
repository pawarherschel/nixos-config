# rpi — minimal headless host.
{ den, ... }:
{
  den.aspects.kats-rpi.includes = [ den.aspects.base ];

  den.aspects.kats-rpi.nixos = {
    age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... FIXME: replace with actual RPi host pubkey";
    system.stateVersion = "23.05";
    home-manager.users.ksakura.home.stateVersion = "26.05";
  };
}
