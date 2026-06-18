# Entity declarations: all hosts, users, and homes.
# Aspects are configured in aspects/, hosts/<name>/, and users/.
{ inputs, ... }: {
  den.hosts.x86_64-linux = {
    kats-laptop.users = {
      ksakura = { };
      kat = {
        # Unprivileged SSH user — no home-manager.
        classes = [ ];
      };
    };
  };

  den.hosts.aarch64-linux.kats-rpi = {
    users.ksakura = { };
    instantiate = args: inputs.nixpkgs.lib.nixosSystem (args // { system = "aarch64-linux"; });
  };
}
