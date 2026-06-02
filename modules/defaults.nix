# den.default — applied to every host and user automatically.
{ lib, den, ... }:
{
  den.default.includes = [
    den.batteries.hostname
    (den.batteries.define-user { })
  ];

  den.default.nixos.nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];
}
