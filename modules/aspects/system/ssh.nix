# system.ssh — OpenSSH server.
{ lib, ... }:
{
  den.aspects.system.ssh.nixos = {
    services.openssh.enable = true;
    services.openssh.settings.PasswordAuthentication = lib.mkDefault true;
    services.openssh.settings.X11Forwarding = lib.mkDefault true;
  };
}
