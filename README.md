# nixos-config

My personal NixOS configuration, managed as a single flake.

| | |
|---|---|
| Host | `nixos` |
| System | `x86_64-linux` |
| Channel | `nixos-unstable` |
| Desktop | COSMIC (Wayland) |
| Bootloader | systemd-boot (UEFI) |
| State version | `25.11` |

## Layout

```
.
├── flake.nix                   # Flake inputs and nixosConfigurations.nixos
├── flake.lock                  # Pinned nixpkgs revision
├── configuration.nix           # The actual system configuration
├── hardware-configuration.nix  # Generated: disks, filesystems, kernel modules
└── .gitignore
```

`configuration.nix` is grouped into sections: core system, desktop, hardware &
AI, programs, system packages, and a block of disabled alternatives kept for
reference.

## Requirements

- Nix with flakes enabled. On an existing NixOS system this is already set in
  `configuration.nix`; otherwise add to `~/.config/nix/nix.conf`:

  ```nix
  experimental-features = nix-command flakes
  ```

- Root privileges for anything that touches the system profile
  (`nixos-rebuild`, `nixos-install`).

## Everyday use

All commands are run from the repository root. The flake attribute is `.#nixos`.

### Rebuild and activate

```bash
sudo nixos-rebuild switch --flake .#nixos
```

This builds the new generation, makes it the boot default, and activates it
immediately.

### Build without activating

Useful for checking that the configuration evaluates and compiles before you
commit to it:

```bash
sudo nixos-rebuild build --flake .#nixos
```

The result is a symlink named `./result` (ignored by git).

### Activate without making it the boot default

```bash
sudo nixos-rebuild test --flake .#nixos
```

A reboot returns you to the previous generation.

### Build and set as next boot default, without activating

```bash
sudo nixos-rebuild boot --flake .#nixos
```

### Build the whole system closure directly

`flake.nix` exposes the system toplevel as the default package:

```bash
nix build .#
```

## Updating

Pinned inputs are recorded in `flake.lock`. To move to newer nixpkgs:

```bash
# Update every input
nix flake update

# ...or only nixpkgs
nix flake update nixpkgs

# Inspect what is currently pinned
nix flake metadata
```

Then rebuild:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

Updating `flake.lock` is a normal commit; keep it in version control so every
machine and every rebuild uses the same revision.

## Rollback

Every rebuild creates a new generation. If something breaks:

```bash
# List generations
sudo nixos-rebuild list-generations

# Switch back to a specific generation
sudo nixos-rebuild switch --rollback

# Or pick an older generation in the systemd-boot menu at startup
```

To free disk space by deleting old generations:

```bash
sudo nix-collect-garbage -d
```

## Formatting

The flake provides `nixfmt` as its formatter:

```bash
nix fmt
```

## Making changes

1. Edit `configuration.nix` (or add a module and import it).
2. Format: `nix fmt`
3. Validate: `sudo nixos-rebuild build --flake .#nixos`
4. Apply: `sudo nixos-rebuild switch --flake .#nixos`
5. Commit, including `flake.lock` if it changed.

To add a package, append it to `environment.systemPackages` in
`configuration.nix` and rebuild. For one-off use, `nix shell nixpkgs#<package>`
avoids touching the system.

> **Flakes and git:** when the directory is a git repository, the flake only
> sees files tracked by git. New files must be `git add`ed before
> `nixos-rebuild` will notice them. If you want to build with untracked files,
> use `--flake path:.#nixos` instead.

## Fresh install

From the NixOS installer ISO:

```bash
# Partition and mount the target, then generate hardware config
sudo nixos-generate-config --root /mnt

# Clone this repository
git clone https://github.com/<user>/nixos-config /mnt/etc/nixos

# Copy the generated hardware config into the repo
sudo cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/nixos-config/

# Install
sudo nixos-install --flake /mnt/etc/nixos/nixos-config#nixos
```

`hardware-configuration.nix` is machine-specific: replace it with the one
generated on the target machine rather than reusing this repo's copy.

## Notes

- **Dual boot with Windows:** `time.hardwareClockInLocalTime = true` keeps the
  hardware clock in local time, as Windows expects.
- **Swap:** a 16 GiB swap file at `/var/lib/swapfile`.
- **Graphics:** Intel VA-API, OpenCL, Level Zero and Vulkan; Ollama runs on the
  Vulkan backend.
- **State version:** `system.stateVersion` is intentionally pinned and should
  not be bumped casually — see the NixOS manual.
- **Secrets:** this repository contains no secrets. If you add any, use
  `sops-nix` or `agenix` rather than committing them.
- `hardware-configuration.nix` contains disk UUIDs. Harmless, but be aware of it
  if the repository is public.
