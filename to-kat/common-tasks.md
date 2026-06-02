# Common Tasks — Day-to-Day Operations

Cheat sheet for building, switching, updating, and extending this configuration.

---

## Building & Switching

```bash
# Build a host (dry run — no changes applied)
nh os build .#kats-laptop

# Build and switch (apply changes to current system)
nh os switch .#kats-laptop

# Build and switch with boot entry (safe rollback)
nh os boot .#kats-laptop

# Just home-manager (user config only)
nh home switch .#ksakura@kats-laptop
```

For WSL or Raspberry Pi, substitute the hostname:
```bash
nh os switch .#wsl
nh os switch .#rpi
```

---

## Testing in a VM

```bash
# Boot kats-laptop config in a QEMU VM
nix run .#vm

# The VM has:
#   - Auto-login (no password prompt)
#   - Password: "vm" (for sudo, etc.)
#   - Intel microcode forced on for VM compatibility
#   - greetd auto-starts GNOME
```

Currently only `kats-laptop` has a VM config. See `modules/vm.nix` and `hosts/kats-laptop/system.nix` (the `virtualisation.vmVariant` block).

---

## Updating Inputs

```bash
# Update all flake inputs to latest
nix flake update

# Update a single input
nix flake update nixpkgs
nix flake update home-manager
```

After updating, regenerate the flake (picks up any new `flake-file.inputs` declarations):
```bash
nix run .#write-flake
```

Then rebuild:
```bash
nh os switch .#kats-laptop
```

---

## Adding a New Program

1. **Create the aspect file**: `modules/aspects/programs/<name>.nix`
   - Use the template from `program-aspect-pattern.md`
2. **Add to includes**: In `modules/aspects/cli/default.nix` (for CLI tools) or directly in the host's `default.nix` (for GUI or host-specific tools)
3. **If it needs a custom package**: Create an overlay first in `modules/overlays/<name>.nix`, then include it from the program aspect
4. **Regenerate flake** (if you added `flake-file.inputs`):
   ```bash
   nix run .#write-flake
   ```
5. **Build to verify**:
   ```bash
   nh os build .#kats-laptop
   ```

**Quick example** — adding the `fd` program:

```nix
# modules/aspects/programs/fd.nix
{ den, ... }:
{
  den.aspects.programs.fd.nixos = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.fd ];
  };
}
```

Then in `cli/default.nix`, add to includes:
```nix
den.aspects.programs.fd   # ← add this line
```

---

## Adding a New Helix LSP Language

1. **Create**: `modules/aspects/programs/helix/<language>.nix`
   - Follow the pattern in `programs/helix/nix.nix`
2. **Include it**: Add to the `includes` list in `programs/helix/default.nix`
3. **If LSP needs an overlay**: Create `modules/overlays/<lsp>.nix` and include it from the language aspect
4. **Build**:
   ```bash
   nh home switch .#ksakura@kats-laptop
   ```

---

## Adding an Overlay (Custom/Pinned Package)

1. **Create**: `modules/overlays/<name>.nix`
   - Declare `flake-file.inputs.<name>`
   - Add the overlay to `nixpkgs.overlays`
   - See `overlays/helium.nix` or `overlays/nil.nix` for examples
2. **Regenerate flake**:
   ```bash
   nix run .#write-flake
   ```
3. **Verify** the input was added:
   ```bash
   nix flake metadata | grep <name>
   ```

---

## Adding a New Host

See `adding-new-hosts.md` for the full step-by-step guide.

Quick summary:
```bash
mkdir -p modules/hosts/<hostname>
# Create default.nix with den.aspects.<hostname>
# Add to hosts/default.nix with user assignments
# Build: nh os build .#<hostname>
```

---

## Adding a GUI Application

GUI applications can live anywhere. Options:

- **`aspects/programs/`** — if it follows the standard program pattern
- **`aspects/gui/`** — if it's a graphical tool (Discord, Steam, etc.)
- **Directly in the host's `default.nix`** — for one-off packages:
  ```nix
  den.aspects.<host>.nixos = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [ gimp inkscape ];
  };
  ```

---

## Regenerating `flake.nix`

`flake.nix` is auto-generated and should not be edited by hand. Run:

```bash
nix run .#write-flake
```

This scans all modules for `flake-file.inputs` declarations and regenerates `flake.nix` with all discovered inputs.

---

## Updating Channel (nixpkgs version)

In `modules/dendritic.nix`, change:
```nix
nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
home-manager.url = "github:nix-community/home-manager/release-26.05";
```

Then:
```bash
nix flake update nixpkgs home-manager
nix run .#write-flake
nh os switch .#kats-laptop
```

**Important**: Keep nixpkgs and home-manager on the same release to avoid version mismatches.

---

## Garbage Collection

```bash
# Remove old generations
sudo nix-collect-garbage -d
nix-collect-garbage -d

# Aggressive: remove everything not in current generation
sudo nix-collect-garbage -d && nix-collect-garbage -d
```
