_:
let
  common = {
    nix.settings = {
      extra-substituters = [
        "https://devenv.cachix.org"
        "https://cache.numtide.com"
      ];
      extra-trusted-public-keys = [
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };
  };
in
{
  den.aspects.system.cachix = {
    nixos = {
      imports = [ common ];
      nix.settings.trusted-users = [
        "root"
        "@wheel"
      ];
    };
    darwin = common;
  };
}
