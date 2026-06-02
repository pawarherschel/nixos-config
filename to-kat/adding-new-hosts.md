# Adding New Hosts

## Where hosts are defined

Hosts require changes in **2–3 places**:

### 1. `modules/hosts/default.nix` — Register the host and its users

Add a new host entry under the appropriate architecture:

```nix
{
  den.hosts.x86_64-linux = {
    kats-laptop.users = { ... };
    wsl.users.ksakura = { };
    ### NEW HOST ###
    desktop.users = {
      ksakura = { };
    };
  };

  den.hosts.aarch64-linux.rpi.users.ksakura = { };
}
```

### 2. `modules/hosts/<hostname>/` — Create a host folder

Each host gets its own folder. Look at `kats-laptop/` as a reference:

```
modules/hosts/kats-laptop/
├── default.nix    # Main: includes aspects and host-specific nixos config
├── hardware.nix   # Hardware-specific: disks, CPU, filesystems
├── locale.nix     # Timezone, language, keyboard layout
└── system.nix     # Mechanical config: bootloader, kernel, nix settings, VM variant
```

#### `default.nix` — The entry point

This is the main file. It lists all aspects the host uses:

```nix
# desktop — generic x86_64 desktop.
{ den, ... }:
{
  den.aspects.desktop = {
    includes = [
      den.aspects.base                  # always include this
      den.aspects.gui.gnome             # or cosmic, or nothing if headless
      den.aspects.networking.networkmanager
      den.aspects.hardware.desktop      # hardware-specific aspects
      den.aspects.desktop.hardware      # from your hardware.nix
      den.aspects.desktop.locale        # from your locale.nix
      den.aspects.desktop.system        # from your system.nix
      # ... any other aspects
    ];

    nixos =
      { pkgs, ... }:
      {
        system.stateVersion = "23.05";

        # Host-specific packages
        environment.systemPackages = with pkgs; [
          firefox
        ];
      };
  };
}
```

> **⚠️ Important:** The aspect name in the `includes` list **must match** the folder/host name exactly. `den.aspects.desktop.hardware` refers to the aspect defined in `hardware.nix`.

#### `hardware.nix` — Filesystem layout, kernel modules

Copy this from `nixos-generate-config` output or from `kats-laptop/hardware.nix`.

#### `locale.nix` — Timezone + i18n

```nix
{ den, ... }:
{
  den.aspects.desktop.locale.nixos = {
    time.timeZone = "America/New_York";
    i18n.defaultLocale = "en_US.UTF-8";
    services.xserver.xkb.layout = "us";
  };
}
```

#### `system.nix` — Bootloader, kernel, nix settings

```nix
{ den, lib, ... }:
{
  den.aspects.desktop.system = {
    includes = [
      den.aspects.system.boot.kernel.zen
      den.aspects.system.boot.limine
      den.aspects.system.fstrim
      den.aspects.system.ssh
      den.aspects.system.tmpfs
      den.aspects.system.zram
    ];

    nixos = {
      boot.loader.efi.canTouchEfiVariables = true;
      nix.settings.max-jobs = 8;
      system.stateVersion = "23.05";

      virtualisation.vmVariant = {
        users.users.ksakura.initialPassword = "vm";
        services.getty.autologinUser = "ksakura";
      };
    };
  };
}
```

### 3. (Optional) `aspects/hardware/` — Hardware-specific modules

If your host needs hardware-specific config (like a GPU driver, laptop support), create a file in `aspects/hardware/`. See `aspects/hardware/t480.nix` or `aspects/hardware/desktop.nix` as examples.

Then include it in the host's `default.nix`:

```nix
includes = [
  den.aspects.hardware.desktop
  ...
];
```

### Headless/minimal hosts (rpi, wsl)

For simple headless hosts, you don't need the full folder structure. Just set it all in one `default.nix`:

```nix
# modules/hosts/my-server/default.nix
{ den, ... }:
{
  den.aspects.my-server.includes = [ den.aspects.base ];

  den.aspects.my-server.nixos.system.stateVersion = "23.05";
}
```

### Build and deploy

```bash
# Build the new host
nix build .#nixosConfigurations.desktop.config.system.build.toplevel

# Or use nh (after running `nix run .#write-flake`)
nh os switch --hostname desktop
```
