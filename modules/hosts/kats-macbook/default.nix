# kats-macbook — Apple Silicon Darwin workstation.
{ den, ... }: {
  den.aspects.kats-macbook = {
    includes = [
      den.aspects.agenix
      den.aspects.programs.social
      den.aspects.networking.tailscale
      den.aspects.system.cachix
    ];

    darwin = {
      age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEjtTkLNB/onegTTdczPrneMsZTzH4QclD9xpzhwc001";
      system.stateVersion = 7;
      system.primaryUser = "bytebeam";
    };
  };
}
