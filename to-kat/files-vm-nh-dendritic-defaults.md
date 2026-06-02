# What `vm.nix`, `nh.nix`, `dendritic.nix`, `defaults.nix` Do

These four files live in `next/modules/` and are **plumbing** — they wire up the
build system but don't contain application-level config.

---

## `defaults.nix` — Default settings for every host/user

**File:** `next/modules/defaults.nix`

```nix
{ lib, den, ... }:
{
  den.default.includes = [
    den.batteries.hostname
    (den.batteries.define-user { })
  ];

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];
}
```

**What it does:**

1. **`den.batteries.hostname`** — Auto-detects the hostname and wires it to the
   correct `den.hosts.<arch>.<hostname>` entry. This is how building on
   `kats-laptop` picks `den.hosts.x86_64-linux.kats-laptop` automatically.
2. **`den.batteries.define-user`** — Creates a skeleton user for each user
   declared in `hosts/default.nix`. This is what makes the users actually exist.
3. **`den.schema.user.classes`** — Sets the default user class to
   `"homeManager"`, meaning users get home-manager unless they explicitly
   override with `classes = [ ]`.

**When to touch it:** Almost never. Only if you want to change the default
behavior for all hosts/users (e.g., disable home-manager by default).

---

## `dendritic.nix` — Framework wiring (den + flake-file)

**File:** `next/modules/dendritic.nix`

```nix
{ inputs, ... }:
{
  imports = [
    (inputs.flake-file.flakeModules.dendritic or { })
    (inputs.den.flakeModules.dendritic or { })
  ];

  systems = [ "x86_64-linux" "aarch64-linux" ];

  flake-file.inputs = {
    den.url = "github:denful/den";
    flake-file.url = "github:vic/flake-file";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    ...
  };
}
```

**What it does:**

1. Imports the **dendritic modules** from both `den` and `flake-file`.
   These allow the directory-tree structure to define the flake outputs.
2. Declares supported **systems** (`x86_64-linux`, `aarch64-linux`).
3. Pins the **input URLs** for flake-file's generated `flake.nix`.
   These are the URLs that get written into `flake.nix` when you
   run `nix run .#write-flake`.

**How it works:** The `import-tree` system reads the `modules/` directory tree.
Each `.nix` file becomes part of the flake outputs automatically.
`dendritic.nix` is the module that tells it *how* to interpret the tree —
specifically that it should use the `den` framework's conventions
(aspects, hosts, users, etc.).

**When to touch it:** Only when you:
- Add a new system architecture
- Add a new flake input
- Update `flake.nix` via `nix run .#write-flake`

---

## `nh.nix` — Expose packages for `nh` (nix helper)

**File:** `next/modules/nh.nix`

```nix
{ den, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = den.lib.nh.denPackages { fromFlake = true; } pkgs;
    };
}
```

**What it does:**

The `nh` tool (`nix helper`) needs flake apps/packages named after each host
to build or switch. This module exposes all hosts as outputs so you can do:

```bash
nh os switch --hostname kats-laptop
```

Without this, `nh` wouldn't know how to find your hosts.

**When to touch it:** Never. It's a one-liner that just works.

---

## `vm.nix` — Launch a test VM

**File:** `next/modules/vm.nix`

```nix
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

**What it does:**

Creates a `nix run .#vm` command that:
1. Builds the **kats-laptop** configuration as a VM
2. Launches it in QEMU

The VM variant includes special settings from `hosts/kats-laptop/system.nix`:
- Auto-login for `ksakura`
- Initial password set to `vm`
- No microcode updates needed

**Usage:**
```bash
# Build and launch the VM
nix run .#vm

# Or build first, then run with extra args
nix run .#vm -- -m 4G -smp 2
```

**When to touch it:** Only if you want to change which host the VM targets,
or add more VM configurations.

---

## Summary

| File | Purpose | Touching frequency |
|------|---------|-------------------|
| `defaults.nix` | Sets hostname, user skeleton, default classes | Rarely |
| `dendritic.nix` | Wires den + flake-file for the tree structure | Adding inputs/changing systems |
| `nh.nix` | Enables `nh os switch` | Never |
| `vm.nix` | `nix run .#vm` for testing | Rarely (change target host) |
