# Glossary

Alphabetical reference of every term used in this configuration.

---

## A

### aspect
A named, composable NixOS configuration fragment. Created via `den.aspects.<path>`. Can contain `includes`, `nixos`, `homeManager`, and `provides`. Every `.nix` file under `modules/` becomes an aspect.

### `den.aspects.<path>`
The namespace path to an aspect. Mirrors the file structure: `aspects/programs/atuin.nix` → `den.aspects.programs.atuin`.

---

## B

### battery
A utility module provided by the `den` framework. Common batteries: `hostname` (auto-detect hostname), `define-user` (auto-create user skeletons).

---

## C

### class (user class)
Controls which configuration modules apply to a user. Currently: `"homeManager"` (default — runs home-manager) or empty list (no home-manager). Set via `den.schema.user.classes`.

### class (host class)
The NixOS module class system. `den` uses `nixos` and `homeManager` classes internally to route config to the right layer.

---

## D

### den
The Dendritic Nix framework. Provides `den.aspects`, `den.lib.parametric`, `den.batteries`, and the `dendritic` flake module.

### dendritic
The name of the `den` and `flake-file` flake modules: `inputs.den.flakeModules.dendritic` and `inputs.flake-file.flakeModules.dendritic`.

### `den.default`
Configuration applied to every host and user automatically. Defined in `modules/defaults.nix`.

### `den.lib.nh.denPackages`
Helper that generates per-system packages named after hosts for `nh` discovery.

### `den.lib.parametric`
Composable, overridable configuration tiers (`atLeast`, `atMost`). Used by quasigod but not this rewrite.

---

## F

### flake-file
A flake-parts module that auto-generates `flake.nix` by collecting `flake-file.inputs` declarations from all modules. Input: `github:vic/flake-file`.

### `flake-file.inputs`
Declarative flake inputs embedded in modules. Example: `flake-file.inputs.nixos-hardware.url = "github:...`. Collected by `flake-file` to regenerate `flake.nix`.

### flake-parts
A flake framework that adds a module system on top of Nix flakes. `den` and `flake-file` are both flake-parts modules.

---

## H

### home-manager
User environment manager for Nix. Manages dotfiles, user services, user packages. Integrated via `inputs.home-manager`.

### host
A NixOS machine configuration. Defined as an entity in `hosts/default.nix` and an aspect in `hosts/<name>/default.nix`.

---

## I

### import-tree
A flake-parts utility that recursively imports every `.nix` file in a directory. Used in `flake.nix`: `inputs.import-tree ./modules`.

### includes
The aspect dependency list. `den.aspects.A.includes = [ den.aspects.B ]` means A pulls in all of B's configuration first. Transitive and deduplicated.

### inputs
Flake inputs (dependencies). Top-level ones in `dendritic.nix`, per-module ones via `flake-file.inputs`.

---

## N

### nh
A CLI tool for NixOS and home-manager: `nh os switch`, `nh home switch`. Integrated via `nh.nix` which exposes per-host packages.

### nixos
The `nixos` attribute of an aspect — contains system-level NixOS configuration (services, packages, hardware settings).

---

## O

### overlay
A function `final: prev: { ... }` that adds or overrides packages in nixpkgs. Stored in `modules/overlays/` and included via `den.aspects.overlays.<name>`.

---

## P

### perSystem
A flake-parts concept for per-architecture outputs. Used in `nh.nix` and `vm.nix`.

### provides
Short for `provides.to-hosts`. A user aspect's mechanism for injecting config into hosts that include that user.

### `provides.to-hosts.nixos`
The user injection pattern: `den.aspects.<user>.provides.to-hosts.nixos = { users.users.<user> = { ... }; }`.

---

## S

### `den.schema.user.classes`
Schema setting for default user classes. Set to `lib.mkDefault [ "homeManager" ]` in `defaults.nix`.

### stylix
A NixOS module for system-wide theming based on base16 color schemes. Configured in `aspects/gui/theme.nix` with a custom "colibri" palette.

### system
In `flake.nix`: the architecture (e.g., `x86_64-linux`, `aarch64-linux`). In aspects: `aspects/system/` contains kernel, bootloader, SSH, etc.

---

## T

### to-hosts
See `provides`.

---

## W

### write-flake
The command `nix run .#write-flake` that regenerates `flake.nix` from all `flake-file.inputs` declarations across modules.
