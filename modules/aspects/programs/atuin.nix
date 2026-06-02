# atuin — shell history with nushell integration.
_: {
  den.aspects.programs.atuin = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.atuin ];
      };

    homeManager = {
      programs.atuin = {
        enable = true;
        enableNushellIntegration = true;
        settings.enter_accept = true;
      };
    };
  };
}
