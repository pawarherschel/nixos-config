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
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      determinate,
      stylix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # NOTE: 'nixos' is the default hostname set by the installer
      nixosConfigurations.kats-laptop = nixpkgs.lib.nixosSystem {
        # NOTE: Change this to aarch64-linux if you are on ARM
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          stylix.nixosModules.stylix
          {
            stylix.enable = true;
            stylix.polarity = "dark";
            stylix.image = ./wallpaper.png;
            stylix.homeManagerIntegration.autoImport = true;
            stylix.autoEnable = true;
            stylix.fonts.monospace.package = pkgs.jetbrains-mono;
            stylix.fonts.monospace.name = "JetBrainsMono NF Regular";
            stylix.fonts.sizes.terminal = 15;
          }

          ./configuration.nix
          {
            environment.systemPackages = [
              inputs.zen-browser.packages."${system}".default
            ];
          }

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
            home-manager.backupFileExtension = "bak";
          }

          determinate.nixosModules.default
        ];
      };

      formatter.${system} = pkgs.alejandra;
      devShells.${system}.default =
        with pkgs;
        mkShell {
          buildInputs = [
            nil
            self.formatter.${system}
          ];
        };
    };
}
