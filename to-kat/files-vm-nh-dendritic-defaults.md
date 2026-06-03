# Wiring Files: `dendritic.nix`, `defaults.nix`, `nh.nix`, `vm.nix`

These four files in `modules/` are the framework backbone. They wire up `den`, `flake-file`, `nh`, and the VM test workflow.

---

## `dendritic.nix` — The Single Wiring Entrypoint

**Path**: `modules/dendritic.nix`

This is the **only file** that imports framework modules and declares the top-level flake inputs. Everything else is just aspects, hosts, and users.

```nix
# den + flake-file wiring. nixpkgs and home-manager kept in sync.
{ inputs, den, ... }:
{
  imports = [
    (inputs.flake-file.flakeModules.dendritic or { })
    (inputs.den.flakeModules.dendritic or { })
    inputs.agenix-rekey.flakeModule
    inputs.home-manager.flakeModules.home-manager
  ];

  den.schema.user.includes = [ den._.mutual-provider ];

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  flake-file.inputs = {
    den.url = "github:denful/den";
    flake-file.url = "github:vic/flake-file";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

### What Each Line Does

| Line | Meaning |
|---|---|
| `imports = [ ... ]` | Imports the `dendritic` flake module from both `flake-file` and `den`, plus `agenix-rekey` and `home-manager` flake modules. The `or { }` prevents errors if the module isn't found. |
| `den.schema.user.includes` | Adds the `mutual-provider` battery to every user, enabling host→user and user→host config forwarding (e.g., `provides.to-users`, `provides.<username>`). |
| `systems = [ ... ]` | Architectures this config targets. Both x86_64 (laptops, WSL) and aarch64 (Raspberry Pi). |
| `flake-file.inputs.den` | The `den` framework itself. |
| `flake-file.inputs.flake-file` | Auto-flake generator. |
| `flake-file.inputs.nixpkgs` | Pinned to `nixos-26.05` (stable). |
| `flake-file.inputs.home-manager` | Pinned to `release-26.05`, following the same nixpkgs. Keeps home-manager and home-manager in sync. |

### Why a Single Wiring File?

In quasigod's config, framework imports and inputs are scattered: `modules/den.nix` wires `den`, individual aspect files declare some inputs, the flake declares others. This rewrite consolidates everything into one place so you always know where to look.

**If you need to add a new top-level framework dependency**, this is the file to edit.

---

## `defaults.nix` — Applied to Every Host and User

**Path**: `modules/defaults.nix`

```nix
# den.default — applied to every host and user automatically.
{
  lib,
  den,
  self,
  inputs,
  ...
}:
{
  den.default.includes = [
    den.batteries.hostname
    (den.batteries.define-user { })
  ];

  den.default.nixos = {
    home-manager.backupFileExtension = "bk";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    environment.etc."nixos-config" = { source = ../.; };

    system.configurationRevision = lib.mkDefault (
      inputs.self.rev or self.rev or "dirty"
    );
  };

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];
}
```

### What Each Line Does

| Line | Meaning |
|---|---|
| `den.batteries.hostname` | Auto-sets `networking.hostName` to the host entity name. You don't need `networking.hostName = "kats-laptop"` anywhere — it's automatic. |
| `den.batteries.define-user { }` | Auto-creates `users.users.<name>.isNormalUser = true` for every user declared in `hosts/default.nix`. With empty args, uses defaults. |
| `home-manager.backupFileExtension` | If home-manager would overwrite an existing dotfile, it renames the old one with a `.bk` suffix instead of failing. Prevents activation errors on existing `gh/config.yml`, `jj/config.toml`, `atuin/config.toml`, etc. |
| `nix.settings.experimental-features` | Required for flakes. |
| `environment.etc."nixos-config"` | Captures the full flake source in the Nix store, so it's available at runtime (safe from accidental deletion). |
| `system.configurationRevision` | Tags the generation with the git/jj revision for rollback identification. |
| `den.schema.user.classes` | Sets the default user class to `[ "homeManager" ]`, meaning home-manager config runs for every user unless overridden (see `kat` user). |

### `lib.mkDefault` and Overrides

The `lib.mkDefault` on `user.classes` means individual user declarations can override it:

```nix
# kat overrides the default — no home-manager
kats-laptop.users.kat = { classes = [ ]; };
```

---

## `nh.nix` — `nh` CLI Integration

**Path**: `modules/nh.nix`

```nix
# Exposes flake apps under the name of each host / home for building with nh.
{ den, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = den.lib.nh.denPackages { fromFlake = true; } pkgs;
    };
}
```

### What It Does

`nh` is a NixOS/home-manager CLI helper (`nh os switch`, `nh home switch`). It discovers available configurations by running `nix flake show` and looking for packages named after hosts and users.

`den.lib.nh.denPackages { fromFlake = true; }` generates per-system packages like:

```
packages.x86_64-linux.kats-laptop
packages.x86_64-linux.kats-wsl
packages.aarch64-linux.kats-rpi
```

`nh` finds these and lets you run:
- `nh os switch .#kats-laptop` — build and switch the NixOS config
- `nh home switch .#ksakura@kats-laptop` — build and switch home-manager for ksakura on kats-laptop

---

## `vm.nix` — `nix run .#vm` Test VM

**Path**: `modules/vm.nix`

```nix
# `nix run .#vm` — launch a test VM of kats-laptop.
{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.vm = pkgs.writeShellApplication {
        name = "vm";
        text =
          let
            host = inputs.self.nixosConfigurations.kats-laptop.config;
          in
          ''
            ${host.system.build.vm}/bin/run-${host.networking.hostName}-vm "$@"
          '';
      };
    };
}
```

### What It Does

Creates `nix run .#vm` which boots a QEMU VM of the `kats-laptop` configuration. The VM variant is configured in `hosts/kats-laptop/system.nix`:

```nix
virtualisation.vmVariant = {
  hardware.cpu.intel.updateMicrocode = lib.mkForce true;   # Intel microcode forced on for VM compatibility
  users.users.ksakura.initialPassword = "vm";               # auto-login password
  services.getty.autologinUser = "ksakura";                 # skip login screen
  services.greetd.settings.initial_session = lib.mkForce {
    user = "ksakura";                                        # auto-start GNOME
  };
};
```

### VM Variant Notes

- **Intel microcode is forced ON** (`lib.mkForce true`) in the VM variant, despite the real hardware defaulting to `config.hardware.enableRedistributableFirmware`. This is for VM compatibility.
- **Password is `vm`** — only in the VM, never on real hardware.
- **Auto-login** — skips greetd and goes straight to GNOME.
