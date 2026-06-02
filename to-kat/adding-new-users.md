# Adding New Users

## Where users are declared

There are **two places** you need to touch:

### 1. `modules/hosts/default.nix` — Register the user on a host

This file declares which users exist on which hosts.

Example — current state:

```nix
{
  den.hosts.x86_64-linux = {
    kats-laptop.users = {
      ksakura = { };           # full user with home-manager
      kat = {
        classes = [ ];         # unprivileged SSH user, no home-manager
      };
    };
  };
}
```

To add a new user `alice` to `kats-laptop`:

```nix
kats-laptop.users = {
  ksakura = { };
  kat = { classes = [ ]; };
  alice = { };                 # <--- new user with home-manager
};
```

- If you omit `classes` (or set `classes = [ "homeManager" ]`), the user gets home-manager.
- If you set `classes = [ ]`, the user gets no home-manager (system user only).

> **Key concept:** `den.schema.user.classes` defaults to `[ "homeManager" ]` (set in `defaults.nix`).

### 2. `modules/users/<username>.nix` — Define the user

Create a file like `modules/users/alice.nix`:

```nix
# alice — description here.
{ den, ... }:
{
  den.aspects.alice.provides.to-hosts.nixos =
    { pkgs, ... }:
    {
      users.users.alice = {
        description = "Alice Example";
        isNormalUser = true;
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        shell = pkgs.nushell;    # or pkgs.bash, pkgs.fish, etc.
      };
    };
}
```

### Full home-manager user example (like `ksakura`)

For a user with home-manager, the pattern is the same. The home-manager config is done separately in the host config's `nixos` block (in `hosts/kats-laptop/default.nix`), where:

```nix
home-manager.users.alice.home.stateVersion = "24.05";
```

And then you'd add a separate home-manager module somewhere (or inline in the host file).

### Quick reference

| User type | `hosts/default.nix` | `users/<name>.nix` | home-manager? |
|-----------|---------------------|--------------------|---------------|
| Full user | `ksakura = { };` | Has `provides.to-hosts.nixos` | Yes (via `defaults.nix`'s `den.schema.user.classes`) |
| SSH-only  | `kat = { classes = [ ]; };` | Has `provides.to-hosts.nixos` | No |
