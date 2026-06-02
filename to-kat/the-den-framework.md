# The `den` Framework — Core Concepts

This file explains every concept you need to understand to work with this configuration. Read this before reading the specific how-to guides.

## Concepts

### `den.aspects.<path>`

An **aspect** is a named, composable configuration fragment. Every `.nix` file under `modules/aspects/` becomes an aspect accessible at `den.aspects.<path>`.

The path mirrors the file structure:

| File | Aspect Path |
|---|---|
| `modules/aspects/base/default.nix` | `den.aspects.base` |
| `modules/aspects/gui/gnome/default.nix` | `den.aspects.gui.gnome` |
| `modules/aspects/programs/helix/nix.nix` | `den.aspects.programs.helix.nix` |
| `modules/aspects/system/boot/kernel/zen.nix` | `den.aspects.system.boot.kernel.zen` |

An aspect can contain:
- **`includes`** — a list of other aspects this one depends on
- **`nixos`** — NixOS-level configuration (system packages, services, hardware settings)
- **`homeManager`** — home-manager configuration (user programs, dotfiles, session variables)
- **`provides.to-hosts.nixos`** — user config injected into any host that declares this user (see below)

### `includes`

The dependency chain. When aspect A `includes` aspect B, all of B's configuration is pulled in before A's.

```nix
den.aspects.gui.gnome = {
  includes = [
    den.aspects.gui          # pulls in greetd, pipewire, theme, xdg
    den.aspects.gui.wayland  # pulls in wl-clipboard
  ];
  nixos = { ... };           # GNOME-specific config
};
```

**Transitivity**: If `gui.gnome` includes `gui`, and `gui` includes `gui.theme`, then `gui.gnome` gets `gui.theme` too. The `den` framework handles deduplication — each aspect is only evaluated once.

### `provides.to-hosts`

The mechanism for **host-independent user configuration**. A user aspect declares what it provides, and hosts that include that user automatically get the config.

```nix
# In users/ksakura.nix:
den.aspects.ksakura.provides.to-hosts.nixos = {
  users.users.ksakura = {
    description = "Kathryn Sakura";
    extraGroups = [ "networkmanager" "wheel" ... ];
    shell = pkgs.nushell;
  };
};
```

When `hosts/default.nix` declares `kats-laptop.users.ksakura = { }`, the config from `provides.to-hosts` is automatically injected. The user file doesn't need to know which hosts exist.

### `den.default`

Applied to **every host and every user** automatically. In `defaults.nix`:

```nix
den.default.includes = [
  den.batteries.hostname                          # auto-detect hostname
  (den.batteries.define-user { })                  # auto-create user skeletons
];
den.schema.user.classes = lib.mkDefault [ "homeManager" ];
```

### `den.batteries`

Utility modules provided by the `den` framework:

- **`den.batteries.hostname`** — Automatically sets `networking.hostName` based on the host's entity name. No need to manually set hostname in each host config.
- **`den.batteries.define-user`** — Auto-creates user entries (`users.users.<name>.isNormalUser = true`) for every user declared in `hosts/default.nix`. With `{ }` (empty args), it uses defaults.

### `den.schema.user.classes`

Controls which "classes" of configuration apply to a user. By default (`lib.mkDefault`), every user gets `[ "homeManager" ]`, meaning home-manager config runs.

To create a user without home-manager (like the SSH-only `kat` user):

```nix
# In hosts/default.nix:
kats-laptop.users.kat = {
  classes = [ ];  # no homeManager → no home-manager config
};
```

### `perSystem`

A flake-parts concept for per-architecture outputs. Used in 3 places in this config:

1. **`nh.nix`** — Exposes `den.lib.nh.denPackages` as packages for the `nh` CLI
2. **`vm.nix`** — Creates `packages.vm` for `nix run .#vm`
3. (Potentially more per-architecture packages in the future)

### `flake-file.inputs`

Declarative flake inputs. Instead of editing `flake.nix` manually, you declare dependencies inside the module that uses them:

```nix
# In aspects/hardware/t480.nix:
flake-file.inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";
```

When you run `nix run .#write-flake`, `flake-file` scans all modules, collects all `flake-file.inputs` declarations, and regenerates `flake.nix`. The generated `flake.nix` has a `# DO-NOT-EDIT` header to remind you.

**Why this matters**: Removing a module (e.g., deleting `hardware/t480.nix`) also removes its dependency from `flake.nix`. No orphan inputs.

### `import-tree`

Recursively imports every `.nix` file in a directory as a flake-parts module. The call in `flake.nix`:

```nix
outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; }
  (inputs.import-tree ./modules);
```

This means:
- Every file under `modules/` is automatically discovered
- File placement IS the import
- No manual import lists anywhere

### `den.lib.nh.denPackages`

Helper that generates per-system packages named after each host. Used by the `nh` tool to discover available configurations:

```nix
# nh.nix:
perSystem = { pkgs, ... }: {
  packages = den.lib.nh.denPackages { fromFlake = true; } pkgs;
};
```

This creates packages like `packages.x86_64-linux.kats-laptop`, `packages.x86_64-linux.wsl`, etc., which `nh` finds via `nix flake show`.

### `den.lib.parametric` (NOT used here, but in quasigod)

Quasigod uses `den.lib.parametric.atLeast` to create composable, overridable configuration tiers. This rewrite chose flat explicit `includes` lists instead. If you ever want to bring back parametric tiers for more complex host family hierarchies, it's available in `den.lib.parametric`.
