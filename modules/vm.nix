# `nix run .#vm` — launch a test VM of the current host.
# `nix run .#vm-kats-laptop` or `nix run .#vm-kats-rpi` — explicit host.
{ inputs, ... }:
let
  hostSystems = {
    kats-laptop = "x86_64-linux";
    kats-rpi = "aarch64-linux";
  };
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages =
        builtins.listToAttrs (
          builtins.map (hostName: {
            name = "vm-${hostName}";
            value = pkgs.writeShellApplication {
              name = "vm-${hostName}";
              text =
                let
                  host = inputs.self.nixosConfigurations.${hostName}.config;
                in
                ''
                  exec '${host.system.build.vm}/bin/run-${host.networking.hostName}-vm' "$@"
                '';
            };
          }) (builtins.attrNames hostSystems)
        )
        // {
          vm = pkgs.writeShellApplication {
            name = "vm";
            text =
              let
                laptop = inputs.self.nixosConfigurations.kats-laptop.config;
                rpi = inputs.self.nixosConfigurations.kats-rpi.config;
              in
              ''
                case "$(hostname)" in
                  kats-laptop) exec '${laptop.system.build.vm}/bin/run-kats-laptop-vm' "$@" ;;
                  kats-rpi)    exec '${rpi.system.build.vm}/bin/run-kats-rpi-vm' "$@" ;;
                  *) echo "Unknown host: $(hostname). Use nix run .#vm-<host>" >&2; exit 1 ;;
                esac
              '';
          };
        };
    };
}
