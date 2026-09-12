# obsidian — knowledge base.
_: {
  den.aspects.programs.obsidian = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.obsidian ];
      };

    provides.ksakura.homeManager = {
      home.file."kats-vault/.obsidian/appearance.json".force = true;

      programs.obsidian = {
        enable = true;
        cli.enable = true;
        vaults.kats-vault.target = "kats-vault";
      };
    };
  };
}
