# system.ssh — OpenSSH server.
{ lib, ... }:
{
  den.aspects.system.ssh.nixos = {
    services = {
      openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = lib.mkDefault true;
          X11Forwarding = lib.mkDefault true;
        };
      };
    };
  };
}
