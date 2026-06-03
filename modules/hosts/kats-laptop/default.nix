# kats-laptop — ThinkPad T480 workstation.
{ den, ... }:
{
  den.aspects.kats-laptop = {
    includes = [
      den.aspects.base
      den.aspects.gui.gnome
      den.aspects.gui.opentabletdriver
      den.aspects.gui.social
      den.aspects.gui.steam
      den.aspects.hardware.t480
      den.aspects.kats-laptop.hardware
      den.aspects.kats-laptop.locale
      den.aspects.kats-laptop.system
      den.aspects.networking.networkmanager
      den.aspects.networking.openvpn
      den.aspects.networking.tailscale
      den.aspects.overlays.pi-coding-agent
      den.aspects.programs.helium
    ];

    nixos =
      { pkgs, ... }:
      {
        system.stateVersion = "23.05";

        home-manager.users.ksakura.home.stateVersion = "26.05";

        age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMLB4iwiBhhog6TCs50yqJ/2uGYHjRw7lus8vdq1m0G1 ksakura@kats-laptop";

        networking.firewall.trustedInterfaces = [ "enp0s31f6" ];

        environment.systemPackages = with pkgs; [
          firefox
          gnome-connections
          moonlight-qt
          nautilus
          pi-coding-agent
          wakeonlan
          waypipe
          zed-editor-fhs
        ];
      };
  };
}
