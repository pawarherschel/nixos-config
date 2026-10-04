# Entity declarations: all hosts, users, and homes.
# Aspects are configured in aspects/, hosts/<name>/, and users/.
{ inputs, den, ... }:
{
  den.hosts = {
    x86_64-linux = {
      kats-laptop.users = {
        ksakura = { };
        kat = {
          # Unprivileged SSH user — no home-manager.
          classes = [ ];
        };
      };
    };

    aarch64-darwin.kats-macbook = {
      home-manager.enable = true;
      users.bytebeam = {
        classes = [ "homeManager" ];
        aspect = den.aspects.bytebeam;
      };
    };

    aarch64-linux.kats-rpi = {
      users.ksakura = { };
      instantiate = args: inputs.nixpkgs.lib.nixosSystem (args // { system = "aarch64-linux"; });
    };
  };
}
