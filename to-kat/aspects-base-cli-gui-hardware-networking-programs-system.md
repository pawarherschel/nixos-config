# Aspect Directory Reference

What goes in each subdirectory under `modules/aspects/`, with a full inventory of every file.

---

## `aspects/base/` — Minimal Foundation

**Purpose**: The bare minimum every host needs. Currently: allow unfree packages + all CLI tools.

| File | What It Does |
|---|---|
| `default.nix` | `includes = [ den.aspects.cli ]` + `nixpkgs.config.allowUnfree = true` |

If you want to add something that literally every host must have (like a kernel hardening setting or a global environment variable), put it here.

---

## `aspects/cli/` — Terminal Programs & Tools

**Purpose**: Standard replacement for GNU coreutils-adjacent tools, plus essential CLI programs.

| File | What It Does |
|---|---|
| `default.nix` | Includes all program aspects below + installs `difftastic`, `ripgrep`, `zellij` as system packages |
| `nix-helpers.nix` | Installs `nh` and `nix-output-monitor` |

**Note**: Most CLI programs live under `aspects/programs/` and are included here. The `cli/default.nix` include list is:

```nix
includes = [
  den.aspects.cli.nix-helpers
  den.aspects.programs.atuin
  den.aspects.programs.bat
  den.aspects.programs.bottom
  den.aspects.programs.gh
  den.aspects.programs.helix
  den.aspects.programs.jujutsu
  den.aspects.programs.kitty
  den.aspects.programs.nushell
  den.aspects.programs.starship
  den.aspects.programs.syncthing
];
```

To add a new CLI program: create it in `programs/`, then add it to this list. See `program-aspect-pattern.md`.

---

## `aspects/gui/` — Graphical Desktop & Display

**Purpose**: Everything graphical — display managers, desktop environments, audio, themes, portals, individual GUI apps.

### Core GUI Infrastructure

| File | What It Does |
|---|---|
| `default.nix` | Base GUI layer: includes `greetd`, `kdeconnect`, `pipewire`, `theme`, `xdg` + enables `polkit` |
| `greetd.nix` | Greetd display manager with `tuigreet` (terminal greeter) |
| `pipewire.nix` | PipeWire audio/video server (replaces PulseAudio) |
| `theme.nix` | stylix + base16 theming with custom "colibri" color scheme + JetBrains Mono fonts. **Also declares flake inputs for `stylix`, `tt-schemes`, and `base16`.** |
| `wayland.nix` | Installs `wl-clipboard` |
| `xdg.nix` | XDG desktop portal configuration |
| `kdeconnect.nix` | KDE Connect for phone integration |

### Desktop Environments

| File | What It Does |
|---|---|
| `gnome/default.nix` | GNOME desktop. Includes `gui` base + `wayland` + `gnome/astra-monitor`. Disables core-apps, dev-tools, games. Adds GNOME extensions (appindicator, clipboard-indicator, paperwm, etc.) |
| `gnome/astra-monitor.nix` | Astra Monitor GNOME extension (system resource monitoring) |
| `cosmic.nix` | COSMIC desktop (Rust-based). Includes `gui` base + `wayland`. |

### GUI Applications

| File | What It Does |
|---|---|
| `social.nix` | Discord + Signal Desktop |
| `steam.nix` | Steam (gaming) |
| `opentabletdriver.nix` | OpenTabletDriver (drawing tablet support) |

### Using GUI Aspects

Pick **one** DE. For GNOME:
```nix
den.aspects.<host>.includes = [ den.aspects.gui.gnome ... ];
```

For COSMIC:
```nix
den.aspects.<host>.includes = [ den.aspects.gui.cosmic ... ];
```

You can also include individual GUI apps without a full DE (useful for minimal hosts):
```nix
den.aspects.<host>.includes = [ den.aspects.gui.steam ];
```

---

## `aspects/hardware/` — Machine-Specific Hardware Profiles

**Purpose**: Hardware-specific NixOS modules. Only included by hosts that need them.

| File | What It Does |
|---|---|
| `t480.nix` | ThinkPad T480 support. Imports `nixos-hardware.nixosModules.lenovo-thinkpad-t480`. |

### Pattern

Hardware aspects import external NixOS modules (like `nixos-hardware`) and declare their own flake input:

```nix
flake-file.inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

den.aspects.hardware.t480.nixos.imports = [
  inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480
];
```

To add a new hardware profile: create a file like `aspects/hardware/framework.nix`, declare the `nixos-hardware` input (it's already declared in `t480.nix`, but you can redeclare — `flake-file` deduplicates), and import the appropriate module.

---

## `aspects/networking/` — Network Configuration

**Purpose**: Network services and clients.

| File | What It Does |
|---|---|
| `networkmanager.nix` | NetworkManager (WiFi, Ethernet, VPN plugins) |
| `openvpn.nix` | OpenVPN client |
| `tailscale.nix` | Tailscale VPN + installs `tailscale` CLI |

### Pattern

Networking aspects are straightforward NixOS config:

```nix
den.aspects.networking.tailscale = {
  nixos = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.tailscale ];
    services.tailscale.enable = true;
  };
};
```

---

## `aspects/programs/` — Individual Program Configurations

**Purpose**: One file per program. Each handles both NixOS (system packages) and home-manager (user config).

| File | What It Does |
|---|---|
| `atuin.nix` | Shell history with nushell integration |
| `bat.nix` | `bat` — cat with syntax highlighting |
| `bottom.nix` | `bottom` — system monitor (like htop) |
| `gh.nix` | GitHub CLI |
| `helium.nix` | Helium browser. Includes overlay, system package, desktop entry, MIME associations |
| `helix/default.nix` | Helix editor. Configures keybindings, cursor, line numbers, indent guides, LSP. Includes language sub-aspects |
| `helix/javascript.nix` | Helix LSP config for JavaScript |
| `helix/json.nix` | Helix LSP config for JSON |
| `helix/markdown.nix` | Helix LSP config for Markdown (currently commented out in includes) |
| `helix/nix.nix` | Helix LSP config for Nix (nil + nixd). Also installs `deadnix`, `nil`, `nixd`, `nixfmt`, `statix` |
| `helix/toml.nix` | Helix LSP config for TOML |
| `helix/typst.nix` | Helix LSP config for Typst |
| `jujutsu.nix` | `jj` — git-compatible VCS |
| `kitty.nix` | Kitty terminal emulator |
| `nushell.nix` | Nushell — modern shell |
| `starship.nix` | Starship prompt |
| `syncthing.nix` | Syncthing file synchronization |

### Pattern

The standard program aspect has 3 sections — see `program-aspect-pattern.md` for the template.

Some programs (like `helium`) also include overlay aspects for adding custom packages to nixpkgs.

---

## `aspects/system/` — System-Level Configuration

**Purpose**: Kernel, bootloader, filesystems, system services.

### `system/boot/`

| File | What It Does |
|---|---|
| `kernel/zen.nix` | Linux Zen kernel (`linuxPackages_zen`) |
| `limine.nix` | Limine bootloader |
| `plymouth.nix` | Plymouth boot splash (currently commented out in kats-laptop includes) |

### Other System Aspects

| File | What It Does |
|---|---|
| `fstrim.nix` | Periodic SSD TRIM |
| `no-auto-upgrade.nix` | Disables automatic NixOS upgrades |
| `ssh.nix` | OpenSSH server with password + X11 forwarding |
| `tmpfs.nix` | `/tmp` on tmpfs (80% of RAM, cleaned on boot) |
| `zram.nix` | ZRAM swap |

---

## `overlays/` — Nixpkgs Overlays (Outside `aspects/`)

**Purpose**: Custom package definitions. Lives outside `aspects/` but aspects reference them via `den.aspects.overlays.<name>`.

| File | What It Does |
|---|---|
| `helium.nix` | Adds `helium` browser to nixpkgs from `github:ominit/helium-browser-flake`. |
| `nil.nix` | Pins `nil` (Nix LSP) to a specific revision with a custom `cargoHash`. |
| `pi-coding-agent.nix` | Adds `pi-coding-agent` to nixpkgs from `github:numtide/llm-agents.nix`. Included by kats-laptop. |

Overlays declare their own flake inputs, so removing the overlay removes the dependency:

```nix
# helium.nix
flake-file.inputs.helium-browser = {
  url = "github:ominit/helium-browser-flake";
  inputs.nixpkgs.follows = "nixpkgs";
};

den.aspects.overlays.helium.nixos.nixpkgs.overlays = [
  (final: prev: { helium = helium-browser.packages.${prev.system}.helium; })
];
```

Then `programs/helium.nix` includes it: `includes = [ den.aspects.overlays.helium ]`.
