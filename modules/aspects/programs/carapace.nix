_: {
  den.aspects.programs.carapace = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.carapace ];
    };

    provides.ksakura.homeManager = {
      programs.carapace = {
        enable = true;
        enableNushellIntegration = true;
      };
    };
  };
}
