# Program Aspect Patterns

Templates for creating new program aspects. Every program under `aspects/programs/` follows one of these patterns.

---

## Pattern 1: Simple Program (no overlay)

For programs already in nixpkgs that have home-manager modules.

**Template**:

```nix
# <program> — <one-line description>
{ den, ... }:
{
  den.aspects.programs.<program> = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.<program> ];
      };

    homeManager = {
      programs.<program> = {
        enable = true;
        # ... program-specific home-manager settings ...
      };
    };
  };
}
```

**Real Example — `atuin.nix`**:

```nix
# atuin — shell history with nushell integration.
{ den, ... }:
{
  den.aspects.programs.atuin = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.atuin ];
      };

    homeManager = {
      programs.atuin = {
        enable = true;
        enableNushellIntegration = true;
        settings.enter_accept = true;
      };
    };
  };
}
```

### Key Points

- **`nixos`** — Install the package system-wide
- **`homeManager`** — Configure the program for the user (dotfiles, integrations)
- File name = aspect name: `atuin.nix` → `den.aspects.programs.atuin`
- After creating, add it to `cli/default.nix` includes list if it's a CLI tool

---

## Pattern 2: Program with Overlay (custom package not in nixpkgs)

For programs that need a custom package added to nixpkgs via an overlay.

### Step 2a: Create the Overlay

Create `modules/overlays/<program>.nix`:

```nix
# Adds <program> to nixpkgs.
{ inputs, den, ... }:
let
  <program>-flake = inputs.<program>-flake;
in
{
  flake-file.inputs.<program>-flake = {
    url = "github:<owner>/<repo>";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.overlays.<program>.nixos.nixpkgs.overlays = [
    (final: prev: {
      <program> = <program>-flake.packages.${prev.system}.<program>;
    })
  ];
}
```

**Real Example — `overlays/helium.nix`**:

```nix
# Adds helium browser to nixpkgs.
{ inputs, den, ... }:
let
  helium-browser = inputs.helium-browser;
in
{
  flake-file.inputs.helium-browser = {
    url = "github:ominit/helium-browser-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.overlays.helium.nixos.nixpkgs.overlays = [
    (final: prev: {
      helium = helium-browser.packages.${prev.system}.helium;
    })
  ];
}
```

### Step 2b: Create the Program Aspect that Uses the Overlay

```nix
# <program> — <description>. Includes overlay, system package, desktop entry, mime.
{ den, ... }:
{
  den.aspects.programs.<program> = {
    includes = [ den.aspects.overlays.<program> ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.<program> ];
      };

    homeManager =
      { pkgs, ... }:
      {
        # ... desktop entry, MIME, etc. ...
      };
  };
}
```

**Real Example — `programs/helium.nix`**: See the actual file — it includes the overlay, installs the system package, and sets up a desktop entry with full MIME type associations.

### Key Points

- Overlay aspect path: `den.aspects.overlays.<name>` — the `overlays/` directory lives outside `aspects/` but is still in the import-tree
- The overlay declares its own `flake-file.inputs` — removing the overlay file removes the dependency
- The program aspect `includes` the overlay, creating the dependency chain
- `inputs.nixpkgs.follows = "nixpkgs"` ensures the overlay's nixpkgs matches ours

---

## Pattern 3: Program with Helix Language Sub-Aspects

For programs that include a language LSP configuration for Helix editor.

### Main Program Aspect

```nix
# programs/helix/default.nix
{ den, lib, ... }:
{
  den.aspects.programs.helix = {
    includes = [
      den.aspects.programs.helix.json
      den.aspects.programs.helix.nix
      # ... more language sub-aspects ...
    ];

    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.helix ];
      environment.variables.EDITOR = "hx";
    };

    homeManager = { lib, ... }: {
      home.sessionVariables.EDITOR = "hx";
      programs.helix = {
        enable = true;
        defaultEditor = true;
        settings = {
          editor.line-number = "relative";
          # ... editor-wide settings ...
        };
      };
    };
  };
}
```

### Language Sub-Aspect

```nix
# programs/helix/nix.nix — Nix language + LSP config + system packages.
{ den, lib, ... }:
{
  den.aspects.programs.helix.nix = {
    includes = [ den.aspects.overlays.nil ];  # ← if the LSP needs an overlay

    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        nil          # LSP server (pinned via overlay)
        nixd         # alternative LSP
        nixfmt       # formatter
        statix       # linter
      ];
    };

    homeManager = { pkgs, lib, ... }:
    let
      nil = lib.getExe pkgs.nil;
      nixd = lib.getExe pkgs.nixd;
      nixfmt = lib.getExe pkgs.nixfmt;
    in {
      programs.helix.languages = {
        language-server.nil.command = nil;
        language-server.nixd.command = nixd;

        language = [{
          name = "nix";
          file-types = [ "nix" ];
          language-servers = [ "nil" "nixd" ];
          formatter.command = nixfmt;
          auto-format = true;
        }];
      };
    };
  };
}
```

### Key Points for Language Sub-Aspects

- File structure: `programs/helix/<language>.nix`
- Aspect path: `den.aspects.programs.helix.<language>`
- Add to the `includes` list in `programs/helix/default.nix`
- Comment out languages you don't use (e.g., `markdown.nix` is commented out)
- If an LSP needs a pinned version, create an overlay in `overlays/` and include it

---

## After Creating a Program Aspect

1. **Add to `cli/default.nix`** includes list (for CLI tools)
2. **Or add directly to a host** includes list (for GUI-only or host-specific programs)
3. **Run `nix run .#write-flake`** if you added any new `flake-file.inputs`
4. **Build** to verify: `nix run .#<hostname>`
