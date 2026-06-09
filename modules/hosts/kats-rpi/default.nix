# kats-rpi — Raspberry Pi 4 (headless).
{ den, ... }:
{
  den.aspects.kats-rpi = {
    includes = [
      den.aspects.base
      den.aspects.hardware.raspberry-pi-4
      den.aspects.kats-rpi.hardware
      den.aspects.kats-rpi.locale
      den.aspects.kats-rpi.system
      den.aspects.networking.tailscale
      den.aspects.networking.networkmanager
    ];

    nixos =
      { pkgs, ... }:
      {
        age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPR7MT8Rl+RkHi98JO4Jmhyu2fhLX9/8qZQh+CrxVEXo root@nixos";

        system.stateVersion = "23.05";
        home-manager.users.ksakura.home.stateVersion = "26.05";

        networking.firewall.enable = false;

        # TODO: extract cloudflared tunnel to an aspect
        users.users.cloudflared = {
          group = "cloudflared";
          isSystemUser = true;
        };
        users.groups.cloudflared = { };
        systemd.services.my_tunnel = {
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [
            "network.target"
            "network-online.target"
            "systemd-resolved.service"
          ];
          serviceConfig = {
            ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token=eyJhIjoiMmFiZDA5YWQ0MTQ5M2JmNWY2ZjA2NDMyMTIyMGNkNWEiLCJ0IjoiYzRkMjhkZTAtY2RlMS00OGJlLTllM2EtYjEwODIxNjBmNTdiIiwicyI6Ik1tUm1PV0l6TVdZdE9EZGpOaTAwWldVMExXRTBZakl0WVdWaU9EazJNMk13T0RNeCJ9";
            Restart = "always";
            User = "cloudflared";
            Group = "cloudflared";
          };
        };

        # TODO: extract remote builder config to a shared aspect (for all hosts)
        programs.ssh.extraConfig = ''
          Host remotebuilder
            Hostname 192.168.0.100
            Port 2222
            User remotebuild
            IdentitiesOnly yes
            IdentityFile /root/.ssh/remotebuild
        '';

        environment.systemPackages = with pkgs; [
          libraspberrypi
          cloudflared
        ];
      };
  };
}
