# hardware.raspberry-pi-4 — Raspberry Pi 4 support.
{ inputs, ... }:
{
  flake-file.inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  den.aspects.hardware.raspberry-pi-4.nixos.imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];
}
