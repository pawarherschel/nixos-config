# cli.nix-helpers — nh and nix-output-monitor.
_: {
  den.aspects.cli.nix-helpers = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          nh
          nix-output-monitor
        ];
      };
  };
}
