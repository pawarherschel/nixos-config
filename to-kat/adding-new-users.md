# Adding a New User

Step-by-step guide for adding a new user to this configuration.

## Step 1: Create the User File

Create `modules/users/<username>.nix`:

```nix
# <username> — <short description>
{ den, ... }:
{
  den.aspects.<username>.provides.to-hosts.nixos =
    { pkgs, ... }:
    {
      users.users.<username> = {
        description = "Full Name";
        extraGroups = [
          "networkmanager"
          "wheel"
          "audio"
          "sound"
          "video"
        ];
        shell = pkgs.nushell;      # or pkgs.bash, pkgs.zsh, etc.
      };
    };
}
```

### What `provides.to-hosts` Does

This is the key pattern. The user file doesn't list which hosts they belong to. Instead, it declares **what config should be injected** into any host that includes this user. The mapping of users to hosts is centralized in `hosts/default.nix`.

This means:
- You define the user once
- You can add them to multiple hosts without editing the user file
- The user config stays clean and host-independent

## Step 2: Assign User to Hosts

In `modules/hosts/default.nix`, add the user to each host they should appear on:

```nix
{
  den.hosts.x86_64-linux = {
    kats-laptop.users = {
      ksakura = { };
      kat = {
        # No home-manager — SSH access only
        classes = [ ];
      };
      <username> = { };    # full user with home-manager
    };

    wsl.users = {
      ksakura = { };
      <username> = { };    # also on WSL
    };
  };
}
```

## Understanding User Classes

| Declaration | Effect |
|---|---|
| `ksakura = { }` | Default classes from `defaults.nix`: `[ "homeManager" ]`. Full home-manager config runs. |
| `kat = { classes = [ ]; }` | Override: no classes. No home-manager. User exists for SSH but gets no dotfiles/programs. |

### How the Default Class Works

In `defaults.nix`:
```nix
den.schema.user.classes = lib.mkDefault [ "homeManager" ];
```

`lib.mkDefault` means every user gets `[ "homeManager" ]` unless they explicitly set `classes` to something else.

## Step 3: Add Home-Manager Config (if desired)

Home-manager config for a user typically lives in the **host** `default.nix`, not in the user file:

```nix
# In hosts/kats-laptop/default.nix:
den.aspects.kats-laptop.nixos = { pkgs, ... }: {
  home-manager.users.<username> = {
    home.stateVersion = "24.05";
    # ... user-specific home-manager config ...
  };
};
```

This is because home-manager config can be host-specific (different paths, different programs available per host). The user file (`users/<username>.nix`) only sets up the NixOS-level user account (groups, shell, description).

## Step 4: Build and Verify

```bash
# Build for a specific host to check for errors
nh os build .#kats-laptop

# Switch home-manager for the user
nh home switch .#<username>@kats-laptop
```

## Complete Example: Adding a "dev" User

```nix
# modules/users/dev.nix
{ den, ... }:
{
  den.aspects.dev.provides.to-hosts.nixos =
    { pkgs, ... }:
    {
      users.users.dev = {
        isNormalUser = true;
        description = "Development User";
        extraGroups = [ "wheel" "networkmanager" "docker" ];
        shell = pkgs.zsh;
      };
    };
}
```

```nix
# In hosts/default.nix — add to kats-laptop:
kats-laptop.users.dev = { };
```

That's it. Build and you have a new user.
