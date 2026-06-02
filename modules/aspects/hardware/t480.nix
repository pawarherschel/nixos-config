# hardware.t480 — ThinkPad T480 support.
{ inputs, ... }:
{
  flake-file.inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  den.aspects.hardware.t480.nixos.imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480
  ];
}
