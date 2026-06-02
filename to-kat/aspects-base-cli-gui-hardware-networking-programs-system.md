# What Each `aspects/` Subdirectory Is For

The `next/modules/aspects/` directory contains reusable configuration modules
organized by domain. Each subdirectory groups related NixOS + home-manager
configurations that can be mixed and matched across hosts.

---

## `aspects/base/` — Foundation (every host gets this)

**Contains:** `default.nix`

```nix
{ den, ... }:
{
  den.aspects.base = {
    includes = [ den.aspects.cli ];
    nixos.nixpkgs.config.allowUnfree = true;
  };
}
```

**What it does:**
- Enables **unfree packages** (like Discord, Steam, VS Code)
- Automatically includes `den.aspects.cli` (so CLI tools come for free)

**How to use:** Every host should include `den.aspects.base` in its `includes` list.
Both `rpi` and `wsl` do this already:

```nix
den.aspects.my-host.includes = [ den.aspects.base ];
```

**When to modify:** If you want to add something *every single host* should have.
Be careful — base is applied to headless servers too.

---

## `aspects/cli/` — Command-line tools

**Contains:** `default.nix`, `nix-helpers.nix`

**`default.nix`** defines the CLI aspect, which includes all the program
configs and adds system packages:

| Included program | What it is |
|-----------------|------------|
| `den.aspects.programs.atuin` | Shell history search |
| `den.aspects.programs.bat` | `cat` with syntax highlighting |
| `den.aspects.programs.bottom` | System monitor (htop replacement) |
| `den.aspects.programs.gh` | GitHub CLI |
| `den.aspects.programs.helix` | Helix editor (Kat's editor) |
| `den.aspects.programs.jujutsu` | Jujutsu version control (jj) |
| `den.aspects.programs.kitty` | Kitty terminal emulator |
| `den.aspects.programs.nushell` | Nushell (Kat's shell) |
| `den.aspects.programs.starship` | Shell prompt |
| `den.aspects.programs.syncthing` | File synchronization |

Also installs: `difftastic`, `ripgrep`, `zellij`.

**`nix-helpers.nix`** adds `nh` (nix helper) and `nix-output-monitor`.

**How to use:** Automatically included via `den.aspects.base`. If you only want
individual programs, import them directly (e.g., `den.aspects.programs.helix`)
instead of the whole CLI group.

---

## `aspects/gui/` — Graphical desktop environment

**Contains:** `default.nix` + many optional sub-modules

**`default.nix`** defines the base GUI aspect — this is the **shared
infrastructure** any desktop needs:

| Sub-aspect | What it provides |
|-----------|-----------------|
| `greetd` | Login manager (tuigreet TUI greeter) |
| `kdeconnect` | Phone integration (KDE Connect) |
| `pipewire` | Audio server (PulseAudio replacement) |
| `theme` | Stylix theming (colibri color scheme, JetBrains Mono font) |
| `xdg` | XDG portals, autostart, terminal-exec |
| `polkit` | Authorization (enabled in default.nix) |

**Desktop environments (pick one):**

| DE aspect | Description |
|----------|-------------|
| `den.aspects.gui.gnome` | GNOME desktop (includes `den.aspects.gui` + wayland + GNOME extensions) |
| `den.aspects.gui.cosmic` | COSMIC desktop (includes `den.aspects.gui` + wayland) |

**Other optional GUI modules:**

| Aspect | What it adds |
|--------|-------------|
| `den.aspects.gui.social` | Discord + Signal |
| `den.aspects.gui.steam` | Steam gaming |
| `den.aspects.gui.opentabletdriver` | Drawing tablet driver |
| `den.aspects.gui.wayland` | Wayland utilities (wl-clipboard) |

**How to use in a host:**

```nix
# Full GNOME desktop
den.aspects.my-host.includes = [
  den.aspects.base
  den.aspects.gui.gnome       # pulls in gui + wayland automatically
  den.aspects.gui.steam       # optional
];
```

---

## `aspects/hardware/` — Hardware-specific configurations

**Contains:** Individual files per machine/family

| File | Applies to |
|------|-----------|
| `t480.nix` | ThinkPad T480 (includes `nixos-hardware` module) |

**Each file should:**
- Import the relevant `nixos-hardware` module (if available)
- Set kernel modules, firmware, and hardware-specific options

**To add new hardware:**

1. Create `aspects/hardware/my-machine.nix`:

```nix
{ inputs, den, ... }:
{
  flake-file.inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  den.aspects.hardware.my-machine.nixos.imports = [
    inputs.nixos-hardware.nixosModules.some-module
  ];
}
```

2. Include it in the host:

```nix
den.aspects.my-host.includes = [
  den.aspects.hardware.my-machine
];
```

---

## `aspects/networking/` — Network services

**Contains:** One file per service

| Aspect | What it enables |
|--------|----------------|
| `den.aspects.networking.networkmanager` | NetworkManager (essential for desktops) |
| `den.aspects.networking.tailscale` | Tailscale VPN (mesh VPN) |
| `den.aspects.networking.openvpn` | OpenVPN client + NM plugin |

**How to use:**

```nix
den.aspects.my-host.includes = [
  den.aspects.networking.networkmanager
  den.aspects.networking.tailscale
];
```

---

## `aspects/programs/` — Individual program configurations

**Contains:** One file per program

These are the leaf configs that get pulled in by `cli/` or imported directly.

| File | What it configures |
|------|-------------------|
| `atuin.nix` | Shell history search |
| `bat.nix` | Syntax-highlighted cat |
| `bottom.nix` | System monitor |
| `gh.nix` | GitHub CLI |
| `helium.nix` | Helium browser (privacy-focused) |
| `helix/` | Helix editor (with per-language configs: nix, json, js, toml, typst) |
| `jujutsu.nix` | jj version control |
| `kitty.nix` | Kitty terminal |
| `nushell.nix` | Nushell shell |
| `starship.nix` | Prompt |
| `syncthing.nix` | File sync |

**Pattern for adding a new program:**

```nix
# aspects/programs/ripgrep.nix
{ den, ... }:
{
  den.aspects.programs.ripgrep.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.ripgrep ];
    };
}
```

Then either include it in `cli/default.nix` or import directly in a host.

---

## `aspects/system/` — System-level mechanical config

**Contains:** Boot, kernel, and system services

| Aspect | What it configures |
|--------|-------------------|
| `system.boot.kernel.zen` | Linux Zen kernel (desktop-optimized) |
| `system.boot.limine` | Limine bootloader |
| `system.boot.plymouth` | Boot splash screen (blahaj shark theme 🦈) |
| `system.fstrim` | SSD TRIM scheduling |
| `system.no-auto-upgrade` | Disable auto-upgrades |
| `system.ssh` | SSH server |
| `system.tmpfs` | tmpfs for `/tmp` |
| `system.zram` | ZRAM swap compression |

**How to use:** Included from `hosts/<name>/system.nix`:

```nix
den.aspects.my-host.system = {
  includes = [
    den.aspects.system.boot.kernel.zen
    den.aspects.system.boot.limine
    den.aspects.system.fstrim
    den.aspects.system.ssh
    den.aspects.system.tmpfs
    den.aspects.system.zram
  ];
};
```

---

## Quick Reference: Aspect Relationships

```
base ──────────────────────────────────────────► includes cli
  │                                                 │
  │                                                 ├── atuin
  │                                                 ├── bat
  │                                                 ├── bottom
  │                                                 ├── gh
  │  host ───► includes base + gui.gnome + ...      ├── helix
  │              │                                   ├── jujutsu
  │              ├── gui ───► greetd                  ├── kitty
  │              │           pipewire                 ├── nushell
  │              │           theme                    ├── starship
  │              │           xdg                      └── syncthing
  │              │
  │              ├── gui.gnome ──► wayland
  │              ├── networking.networkmanager
  │              ├── hardware.t480
  │              └── system ──► boot.kernel.zen
  │                             boot.limine
  │                             fstrim
  │                             ssh
  │                             tmpfs
  │                             zram
```
