# to-kat — Dendritic Nix Orientation Guide

A handbook for understanding, extending, and maintaining this Dendritic Nix configuration. Written for Kathryn (future you, after months of not touching Nix).

## Suggested Reading Order

| # | File | What It Covers |
|---|---|---|
| 1 | `architecture-overview.md` | Big-picture: what Dendritic Nix is, how the old layout compares, the new `next/` structure |
| 2 | `the-den-framework.md` | Core framework concepts: aspects, includes, provides, batteries, perSystem, flake-file |
| 3 | `files-vm-nh-dendritic-defaults.md` | The four wiring files: `dendritic.nix`, `defaults.nix`, `nh.nix`, `vm.nix` |
| 4 | `aspects-base-cli-gui-hardware-networking-programs-system.md` | Reference for every aspect directory — what goes where |
| 5 | `adding-new-hosts.md` | Step-by-step guide for declaring a new host |
| 6 | `adding-new-users.md` | Step-by-step guide for adding a new user |
| 7 | `program-aspect-pattern.md` | Templates for creating new program aspects |
| 8 | `secrets-management.md` | Secrets workflow: agenix, rekeying, creating/editing secrets |
| 9 | `common-tasks.md` | Day-to-day operations: build, switch, test VM, update, add programs |
| 10 | `GLOSSARY.md` | Alphabetical reference of all terminology |

## Quick Start

If you only have 5 minutes, read files 1–3. They cover the architecture, core concepts, and the four wiring files that make everything work.

## Naming Conventions

- **Files are descriptive, not numbered** — easier to find and reorder later.
- **`to-kat/`** is a reference folder, not Nix code — nothing in here affects the build.
