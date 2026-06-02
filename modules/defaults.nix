# den.default — applied to every host and user automatically.
{ lib, den, ... }:
{
  den.default.includes = [
    den.batteries.hostname
    (den.batteries.define-user { })
  ];

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];
}
