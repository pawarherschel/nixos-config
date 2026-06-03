# Secrets Management

This configuration uses **agenix** + **agenix-rekey** for secret management. Secrets are encrypted with a master key and automatically re-encrypted per-host at deploy time.

## Architecture

```
                     master key
                    (your SSH key)
                         │
                    ┌────▼────┐
                    │ gitKey  │  ← master-encrypted .age file in repo
                    │ .age    │
                    └────┬────┘
                         │
                   agenix-rekey
                         │
              ┌──────────┼──────────┐
              │          │          │
         ┌────▼────┐ ┌──▼──┐  ┌───▼───┐
         │kats-    │ │kats-│  │kats-  │  ← per-host encrypted
         │laptop   │ │wsl  │  │rpi    │    copies in secrets/
         └─────────┘ └─────┘  └───────┘
```

- **Source secrets** live in their aspect folder (e.g. `modules/aspects/programs/git/gitKey.age`)
- Encrypted with your **master identity** (`~/.config/agenix/identity.txt`, converted from `~/.ssh/id_ed25519`)
- **Host-specific rekeyed copies** live in `secrets/rekeyed/<hostname>/` (auto-generated, committed)
- At boot, the agenix NixOS module decrypts using the **host's SSH key** (`/etc/ssh/ssh_host_ed25519_key`)

## Key Files

| File | Purpose |
|---|---|
| `modules/aspects/agenix/default.nix` | agenix NixOS module import |
| `modules/aspects/agenix/agenix-rekey.nix` | agenix-rekey module, storage mode, local storage dir |
| `modules/users/ksakura.nix` | Master identity path (`/home/ksakura/.config/agenix/identity.txt`) |
| `modules/hosts/<host>/default.nix` | Per-host `age.rekey.hostPubkey` |
| `modules/aspects/programs/*/default.nix` | Per-secret `rekeyFile` declarations |
| `secrets/rekeyed/<host>/*.age` | Auto-generated host-specific encrypted secrets |
| `~/.config/agenix/identity.txt` | Your master age private key (NOT in repo) |

## Common Tasks

### Create a New Secret

```bash
agenix edit path/to/secret.age
```

Paste the secret value, save, exit. Then declare it in a NixOS module:

```nix
age.secrets.mysecret.rekeyFile = ./path/to/secret.age;
```

Then rekey and deploy:

```bash
agenix rekey -a
nh os test .
```

### Edit an Existing Secret

```bash
agenix edit modules/aspects/programs/git/gitKey.age
```

Make changes, save, exit. Then rekey:

```bash
agenix rekey -a
nh os test .
```

### View a Secret

```bash
# Via the CLI (interactive picker)
agenix view

# Directly decrypt the master-encrypted file
rage -d -i ~/.config/agenix/identity.txt path/to/secret.age

# On a deployed system, check the runtime path
cat /run/agenix/gitKey
```

### Add a New Host

1. Add the host's SSH pubkey in the host module:
   ```nix
   age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...";
   ```

2. Create the rekeyed secrets directory:
   ```bash
   mkdir -p secrets/rekeyed/<hostname>
   ```

3. Rekey all secrets for the new host:
   ```bash
   agenix rekey -a
   ```

### Bootstrap a New Machine

When setting up a new machine that doesn't have SSH host keys yet:

```bash
# Rekey with a dummy placeholder first
agenix rekey --dummy
```

Then deploy. After the machine boots and generates its SSH host key, update `age.rekey.hostPubkey` and rekey for real.

### Rotate Master Key

If you change your SSH key:

1. Convert the new key: `ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/agenix/identity.txt`
2. Re-encrypt all secrets with the new identity:
   ```bash
   agenix update-masterkeys
   agenix rekey -a
   ```

## How Decryption Works at Boot

1. The agenix NixOS module runs an activation script
2. It reads the host's SSH private key (`/etc/ssh/ssh_host_ed25519_key`)
3. It decrypts each `.age` file in `secrets/rekeyed/<host>/` (these are encrypted with the host's pubkey)
4. Decrypted secrets are mounted at `/run/agenix/<name>`
5. Services reference them via `config.age.secrets.<name>.path`

## Troubleshooting

**`agenix rekey` fails with "No matching keys found"**
→ Your master identity doesn't match the key the secret was encrypted with. Check `~/.config/agenix/identity.txt` matches what was used to create the secret.

**`/run/agenix` doesn't exist after deploy**
→ The host can't decrypt the rekeyed secret. Make sure `age.rekey.hostPubkey` matches the host's actual SSH key. Rekey with `agenix rekey -a`.

**`agenix rekey` says "dummy value"**
→ A host's pubkey is unknown. Either add a dummy placeholder to proceed or set the real pubkey first.
