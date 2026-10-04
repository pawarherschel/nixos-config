# kats-macbook — Apple Silicon Darwin workstation.
{ den, ... }: {
  den.aspects.kats-macbook = {
    includes = [
      den.aspects.agenix
      den.aspects.programs.social
      den.aspects.networking.tailscale
    ];

    darwin = {
      system.stateVersion = 7;
      system.primaryUser = "bytebeam";
    };
  };
}
