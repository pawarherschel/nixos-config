# Entity declarations: all hosts, users, and homes.
# Aspects are configured in aspects/, hosts/<name>/, and users/.
{
  den.hosts.x86_64-linux = {
    kats-laptop.users = {
      ksakura = { };
      kat = {
        # Unprivileged SSH user — no home-manager.
        classes = [ ];
      };
    };
    wsl.users.ksakura = { };
  };

  den.hosts.aarch64-linux.rpi.users.ksakura = { };
}
