# atuin — shell history with nushell integration.
_: {
  den.aspects.programs.atuin = {
    homeManager = {
      programs.atuin = {
        enable = true;
        enableNushellIntegration = true;
        settings.enter_accept = true;
      };
    };
  };
}
