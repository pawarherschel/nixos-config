# /etc/nixos/flake.nix
{
  inputs = {
    # NOTE: Replace "nixos-23.11" with that which is in system.stateVersion of
    # configuration.nix. You can also use latter versions if you wish to
    # upgrade.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ self, nixpkgs, home-manager, ... }: {
    # NOTE: 'nixos' is the default hostname set by the installer
    nixosConfigurations.kats-laptop = nixpkgs.lib.nixosSystem {
      # NOTE: Change this to aarch64-linux if you are on ARM
      system = "x86_64-linux";
      # extraSpecialArgs = {inherit inputs;};
      modules = [ 
      ./configuration.nix 
      
      {
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
      }
      
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        # home-manager.useUserPkgs = true;
        home-manager.users.ksakura = import ./home.nix;
      }
      ];
    };
  };
}
