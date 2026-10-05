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
      environment.etc.hosts = {
        # Allow activation to back up and replace this Mac's original hosts file.
        knownSha256Hashes = [ "c7dd0e2ed261ce76d76f852596c5b54026b9a894fa481381ffd399b556c0e2da" ];
        text = ''
          127.0.0.1 localhost kats-macbook
          255.255.255.255 broadcasthost
          ::1 localhost
        '';
      };
    };
  };
}
