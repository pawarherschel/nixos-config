# Adding a New Host

Step-by-step guide for adding a new machine to this configuration.

## Step 1: Create the Host Directory

```bash
mkdir -p modules/hosts/<hostname>
```

## Step 2: Create the Host Aspect

Create `modules/hosts/<hostname>/default.nix`:

```nix
# <hostname> — <short description>
{ den, ... }:
{
  den.aspects.<hostname> = {
    includes = [
      den.aspects.base
      # den.aspects.gui.gnome     ← uncomment for graphical hosts
      # den.aspects.gui.cosmic    ← alternative DE
      # den.aspects.hardware.t480 ← add hardware profiles
      # den.aspects.networking.* ← add networking
      # den.aspects.programs.*   ← add extra programs not in cli
    ];

    nixos =
      { pkgs, ... }:
      {
        system.stateVersion = "23.05"; # ← set to the NixOS version at install time
      };
  };
}
```

### What to Include

| Type of Host | Typical Includes |
|---|---|
| **Minimal CLI** (WSL, RPi) | `den.aspects.base` only |
| **Desktop/Laptop** | `base` + `gui.gnome` or `gui.cosmic` + hardware profile + networking |
| **Headless Server** | `base` + `system.ssh` + `system.zram` + maybe specific services |

### Host-Specific Sub-Aspects

For complex hosts, split into sub-files (like `kats-laptop` does):

```
hosts/<hostname>/
├── default.nix     ← aspect includes + stateVersion + systemPackages
├── hardware.nix    ← fileSystems, kernelModules, CPU settings
├── locale.nix      ← timezone, i18n, keyboard layout
└── system.nix      ← bootloader, kernel, kernel tuning, extra settings
```

Each sub-file declares its own aspect:

```nix
# hosts/<hostname>/hardware.nix
{ den, lib, ... }:
{
  den.aspects.<hostname>.hardware.nixos = {
    fileSystems."/" = { device = "..."; fsType = "ext4"; };
    ...
  };
}
```

Then include them in the main aspect:

```nix
den.aspects.<hostname>.includes = [
  den.aspects.<hostname>.hardware
  den.aspects.<hostname>.locale
  den.aspects.<hostname>.system
  ...
];
```

### Hardware Profiles

For common hardware, use aspects from `aspects/hardware/`. Currently available:

- `den.aspects.hardware.t480` — ThinkPad T480 (imports `nixos-hardware`)

To add a new hardware profile (e.g., a Framework laptop), create `aspects/hardware/framework.nix`:

```nix
# aspects/hardware/framework.nix
{ inputs, den, ... }:
{
  flake-file.inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  den.aspects.hardware.framework.nixos.imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480 # TODO: replace with framework module
  ];
}
```

(`flake-file` deduplicates `nixos-hardware` if another aspect already declared it.)

## Step 3: Declare Users

In `modules/hosts/default.nix`, add the host under the correct architecture:

```nix
{
  den.hosts.x86_64-linux = {
    kats-laptop.users = { ... };
    wsl.users.ksakura = { };
    <hostname>.users = {
      ksakura = { };   # full user with home-manager
      # kat = { classes = [ ]; };   # SSH-only, no home-manager
    };
  };

  # For ARM hosts:
  # den.hosts.aarch64-linux.<hostname>.users.ksakura = { };
}
```

### User Classes

- `{ }` (empty) — inherits default `classes = [ "homeManager" ]` from `defaults.nix`. Full home-manager config runs.
- `{ classes = [ ]; }` — no home-manager. Use for unprivileged or service users.

## Step 4: Build and Test

```bash
# Build (dry run)
nix run .#<hostname>    # if using nix run
nh os build .#<hostname>

# Build and switch (on the actual machine)
nh os switch .#<hostname>

# Test in a VM (if you added a VM config)
# See vm.nix — currently only kats-laptop has a VM
```

## Example: Adding a New Desktop Host

Here's a complete example for a fictional "framework" laptop:

```nix
# modules/hosts/framework/default.nix
{ den, ... }:
{
  den.aspects.framework = {
    includes = [
      den.aspects.base
      den.aspects.gui.gnome
      den.aspects.gui.social
      den.aspects.gui.steam
      den.aspects.hardware.framework    # you'd need to create this
      den.aspects.networking.networkmanager
      den.aspects.networking.tailscale
    ];

    nixos = { pkgs, ... }: {
      system.stateVersion = "25.05";
      environment.systemPackages = with pkgs; [ firefox ];
    };
  };
}
```

```nix
# In hosts/default.nix:
den.hosts.x86_64-linux.framework.users.ksakura = { };
```

Now build: `nh os build .#framework`
