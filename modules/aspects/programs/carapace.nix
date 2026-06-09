_: {
  den.aspects.programs.carapace = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.carapace ];
    };

    homeManager = {
      programs.carapace = {
        enable = true;
        enableNushellIntegration = true;
      };
    };
  };
}
