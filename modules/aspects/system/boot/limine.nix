# system.boot.limine — Limine boot loader.
{ den, ... }:
{
  den.aspects.system.boot.limine.nixos.boot.loader.limine.enable = true;
}
