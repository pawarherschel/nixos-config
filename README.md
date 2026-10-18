# Getting Started Guide

Steps you can follow after cloning this template:

- Be sure to read the [den documentation](https://den.denful.dev)

- Update den input.

```console
nix flake update den
```

- Edit [modules/hosts.nix](modules/hosts.nix)

- Build

```console
# default action is build
nix run .#igloo

# pass any other nh action
nix run .#igloo -- switch
```

- Run the VM

We recommend to use a VM develop cycle so you can play with the system before applying to your hardware.

See [modules/vm.nix](modules/vm.nix)

```console
nix run .#vm
```

## connectome-host (kats-macbook)

The Darwin host installs `connectome-host`, including its browser UI. The overlay
is in `modules/overlays/connectome-host/`; source is pinned through `flake.lock`,
and `bun.nix` vendors the matching dependency expressions. `references/` is not
needed to evaluate, build, or run the package.

Run `connectome-host path/to/recipe.json` from a writable working directory.
The launcher preserves that directory: `.env`, MCP registries, and the default
`./data` belong to it. No agent service or credentials are configured.

To update, change `rev` in the overlay's `default.nix`, regenerate `bun.nix` from
that revision's `bun.lock` using the flake's pinned bun2nix CLI, regenerate the
flake with `nix run .#write-flake`, and update the source lock and web UI
`npmDepsHash`. Build and run the shipped offline `recipes/mock-test.json` before
switching the Darwin host.

## Codiff (kats-macbook)

The Darwin host installs Codiff 1.16.2 from the signed Apple Silicon release.
`modules/overlays/codiff.nix` pins its version and archive checksum and exposes
both `/Applications/Nix Apps/Codiff.app` and the `codiff` terminal helper after
`sudo darwin-rebuild switch --flake .#kats-macbook`.

Run `codiff /path/to/repository`. The upstream app is unpatched; jj revsets are
not supported. To update, change the version and checksum in the overlay.

## Helix Steel plugins

`modules/aspects/programs/helix/` uses the pinned `nhx` Home Manager module.
`steelix.nix` pins the plugin-enabled mattwparas editor separately from nixpkgs
and keeps its grammar/query runtime paired. `references/` is research-only;
it is not an evaluation, build, or runtime dependency.

Enabled plugins: smooth-scroll, oil, forest, who, breadcrumbs, context, eval,
juju, lsp-picker, scopeline, notify, paredit, and previously. Cliff and Vista
require other editor forks; Scooter's native Steel ABI is incompatible with
this editor. Those three are intentionally omitted.

Invoke plugins with colon commands, including `:oil`, `:forest-open`,
`:who-toggle`, `:breadcrumbs`, `:hx-eval-prompt`, `:juju-status`, `:lsp-picker`,
`:previously`, and `:half-page-down-smooth`. Who starts disabled. Context and
Scopeline activate during startup. No global plugin keybindings are added.
Oil's buffer alone maps Enter to open, Backspace to parent, Ctrl-s to apply
filesystem edits, and q to close.

Plugin-specific files under `helix/plugins/` declare their executable
dependencies in `programs.nhx.requiredPackages`; the editor wrapper scopes
them to its own PATH. GNU coreutils supplies the `stat --printf` needed by Oil
on macOS. Steel cogs live under `~/.local/share/steel`.
`plugins/notify.nix` patches Notify's unfocused cursor callback to return
`#false`, as required by the pinned editor's optional-position contract.

After updating pins, regenerate with `nix run .#write-flake`, lock inputs, build
the host's Home Manager activation package, and launch its actual `hx` binary
to check plugin startup and commands before switching the host. A successful
build or `hx --health` does not establish that Steel initialization succeeds.
